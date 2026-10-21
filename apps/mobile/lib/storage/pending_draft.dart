import 'dart:convert';

/// Schema version of the pending record. Only 1 exists in M.4; a future format
/// change bumps this so an old record is detected rather than misread
/// (`design.md` § 4.2).
const int kPendingDraftVersion = 1;

/// Expiry window for a saved report, in hours. This is an application policy
/// value, not something the reporter can change (FR-4.4). It can be overridden
/// per build without touching code:
///
/// ```
/// flutter build --dart-define=SAFESIGNAL_PENDING_DRAFT_TTL_HOURS=48
/// ```
const int kPendingDraftExpiryHours = int.fromEnvironment(
  'SAFESIGNAL_PENDING_DRAFT_TTL_HOURS',
  defaultValue: 24,
);

/// Thrown when a stored record cannot be trusted: an unknown version, a missing
/// field, or a payload that is not the expected object.
///
/// This is deliberately distinct from a JSON *parse* failure. A document that
/// does not parse is a broken value; a document that parses but describes
/// something else is a corrupt record. The store deletes a corrupt record and
/// tells the user (`design.md` § 4.3, SR-4.2).
class PendingDraftCorruptException implements Exception {
  const PendingDraftCorruptException(this.reason);

  /// Why the record was rejected. Never contains report content.
  final String reason;

  @override
  String toString() => 'PendingDraftCorruptException: $reason';
}

/// The saved pending report: the payload that would be sent, the idempotency
/// key issued for it, the timestamps, and a checksum over all of it.
///
/// A pure value object. It performs no I/O and knows nothing about storage:
/// writing and reading the record is the store's job (T-11, T-12). What it does
/// own is describing itself exactly, proving its own integrity, and saying when
/// it has expired (FR-1.3, FR-4.1, SR-3.4, SR-4.1).
class PendingDraft {
  const PendingDraft({
    required this.payload,
    required this.key,
    required this.createdAt,
    required this.expiresAt,
    this.version = kPendingDraftVersion,
    this.storedChecksum,
  });

  /// Record format version. Only [kPendingDraftVersion] is understood.
  final int version;

  /// The exact payload that would be POSTed to the server, in the canonical
  /// field order produced by `ReportApi.payload(draft)`.
  final Map<String, Object?> payload;

  /// The idempotency key issued for this payload. Treated as sensitive: it is
  /// protected by the same envelope as the payload (`design.md` § 4.4).
  final String key;

  /// Creation time in epoch milliseconds, from the client clock.
  final int createdAt;

  /// Expiry time in epoch milliseconds. Computed at save time.
  final int expiresAt;

  /// The checksum carried by the record as it was read from storage. `null` for
  /// a record built in code, which has no stored checksum to compare against.
  final String? storedChecksum;

  /// The canonical payload string: exactly the bytes that will be POSTed.
  /// `jsonEncode` writes no whitespace and preserves insertion order, so this
  /// is stable for a given payload (`design.md` § 4.2, RR-2.3).
  String get canonicalPayload => jsonEncode(payload);

  /// The canonical string the checksum is computed over. The checksum field
  /// itself is excluded (`design.md` § 4.2).
  String get canonicalString =>
      '$version|$canonicalPayload|$key|$createdAt|$expiresAt';

  /// SHA-256 of [canonicalString], lower-case hex.
  String get computedChecksum => sha256Hex(canonicalString);

  /// The checksum this record carries: the one read from storage, or the
  /// computed one for a record built in code.
  String get checksum => storedChecksum ?? computedChecksum;

  /// Whether the record's own checksum matches its content. A record that does
  /// not verify is corrupt and must never be submitted (SR-4.1).
  bool verifyChecksum() => checksum == computedChecksum;

  /// Whether the expiry timestamp has been reached. The record is deleted and
  /// not offered for restore once this is true (FR-4.2).
  bool isExpired(DateTime now) => now.millisecondsSinceEpoch >= expiresAt;

  /// The expiry timestamp for a record created at [createdAt], using the
  /// configured expiry window.
  static int expiryFor(DateTime createdAt) =>
      createdAt.millisecondsSinceEpoch + kPendingDraftExpiryHours * 3600 * 1000;

  /// The record as a JSON-ready map. The payload is written as its canonical
  /// string so that the exact bytes to POST survive the round trip.
  Map<String, Object?> toJson() => <String, Object?>{
        'version': version,
        'payload': canonicalPayload,
        'key': key,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'checksum': checksum,
      };

  /// Rebuild a record from its stored JSON.
  ///
  /// Throws [PendingDraftCorruptException] when the record cannot be trusted.
  /// An unknown version is corrupt, not a parse failure: it means the record was
  /// written by a different format, not that the value is broken.
  static PendingDraft fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int) {
      throw const PendingDraftCorruptException('missing or non-integer version');
    }
    if (version != kPendingDraftVersion) {
      throw PendingDraftCorruptException('unsupported record version $version');
    }

    final key = json['key'];
    if (key is! String) {
      throw const PendingDraftCorruptException('missing or non-string key');
    }
    final createdAt = json['createdAt'];
    if (createdAt is! int) {
      throw const PendingDraftCorruptException('missing or non-integer createdAt');
    }
    final expiresAt = json['expiresAt'];
    if (expiresAt is! int) {
      throw const PendingDraftCorruptException('missing or non-integer expiresAt');
    }
    final checksum = json['checksum'];
    if (checksum is! String) {
      throw const PendingDraftCorruptException('missing or non-string checksum');
    }

    return PendingDraft(
      version: version,
      payload: _payloadFrom(json['payload']),
      key: key,
      createdAt: createdAt,
      expiresAt: expiresAt,
      storedChecksum: checksum,
    );
  }

  /// Accepts the payload either as its canonical string or as an object, and
  /// returns the canonical map. Both forms describe the same bytes, so the
  /// checksum is the same either way.
  static Map<String, Object?> _payloadFrom(Object? raw) {
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    if (raw is String) {
      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        throw const PendingDraftCorruptException('payload is not valid JSON');
      }
      if (decoded is! Map) {
        throw const PendingDraftCorruptException('payload is not an object');
      }
      return decoded.cast<String, Object?>();
    }
    throw const PendingDraftCorruptException('missing payload');
  }
}

/// SHA-256 of [input], lower-case hex (FIPS 180-4).
///
/// Implemented here rather than pulled in as a package: M.4 allows exactly one
/// new client dependency — `flutter_secure_storage` (D-H) — and the checksum is
/// an integrity check over the record's own bytes, not a security control: the
/// record itself is encrypted by the platform keystore (`design.md` § 4.1,
/// § 4.3). The implementation is pinned to the FIPS test vectors in
/// `test/pending_draft_test.dart`.
String sha256Hex(String input) {
  final message = utf8.encode(input);
  final bitLength = message.length * 8;

  final buffer = List<int>.from(message)..add(0x80);
  while (buffer.length % 64 != 56) {
    buffer.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    buffer.add((bitLength >> (i * 8)) & 0xff);
  }

  final h = List<int>.from(_sha256Initial);
  final w = List<int>.filled(64, 0);

  for (var offset = 0; offset < buffer.length; offset += 64) {
    for (var i = 0; i < 16; i++) {
      final j = offset + i * 4;
      w[i] = (buffer[j] << 24) |
          (buffer[j + 1] << 16) |
          (buffer[j + 2] << 8) |
          buffer[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }

    var a = h[0];
    var b = h[1];
    var c = h[2];
    var d = h[3];
    var e = h[4];
    var f = h[5];
    var g = h[6];
    var hh = h[7];

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & g);
      final temp1 = (hh + s1 + ch + _sha256Constants[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;

      hh = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    h[0] = (h[0] + a) & 0xffffffff;
    h[1] = (h[1] + b) & 0xffffffff;
    h[2] = (h[2] + c) & 0xffffffff;
    h[3] = (h[3] + d) & 0xffffffff;
    h[4] = (h[4] + e) & 0xffffffff;
    h[5] = (h[5] + f) & 0xffffffff;
    h[6] = (h[6] + g) & 0xffffffff;
    h[7] = (h[7] + hh) & 0xffffffff;
  }

  final out = StringBuffer();
  for (final value in h) {
    out.write(value.toRadixString(16).padLeft(8, '0'));
  }
  return out.toString();
}

int _rotr(int value, int bits) =>
    ((value >> bits) | (value << (32 - bits))) & 0xffffffff;

const List<int> _sha256Initial = <int>[
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

const List<int> _sha256Constants = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, //
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];
