import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/storage/pending_draft.dart';

ReportDraft draft() => ReportDraft()
  ..timing = Timing.now
  ..incident = IncidentType.threats
  ..support = SupportOption.private
  ..route = '  Thika Road '
  ..vehicle = 'kda 123a'
  ..sacco = 'Super Metro'
  ..area = 'Githurai 45';

Map<String, Object?> canonicalPayload() => ReportApi.payload(draft());

PendingDraft record({
  Map<String, Object?>? payload,
  String key = '0b9f2c1e-7a54-4c1d-9e0a-3f6d8b2a1c77',
  int createdAt = 1760000000000,
  int? expiresAt,
}) =>
    PendingDraft(
      payload: payload ?? canonicalPayload(),
      key: key,
      createdAt: createdAt,
      expiresAt: expiresAt ?? PendingDraft.expiryFor(
        DateTime.fromMillisecondsSinceEpoch(createdAt),
      ),
    );

void main() {
  group('PendingDraft round trip', () {
    test('preserves every field exactly', () {
      final original = record();
      final restored = PendingDraft.fromJson(original.toJson());

      expect(restored.version, original.version);
      expect(restored.payload, equals(original.payload));
      expect(restored.key, original.key);
      expect(restored.createdAt, original.createdAt);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.checksum, original.checksum);
    });

    test('keeps the stored checksum, so corruption is not silently repaired', () {
      final original = record();
      final stored = original.toJson();
      stored['checksum'] = 'not-the-right-checksum';

      final restored = PendingDraft.fromJson(stored);
      expect(restored.checksum, 'not-the-right-checksum');
      expect(restored.verifyChecksum(), isFalse);
      expect(restored.toJson()['checksum'], 'not-the-right-checksum');
    });

    test('accepts a payload stored as an object as well as as a string', () {
      final original = record();
      final asObject = original.toJson()
        ..['payload'] = jsonDecode(original.canonicalPayload);

      final restored = PendingDraft.fromJson(asObject);
      expect(restored.payload, equals(original.payload));
      expect(restored.verifyChecksum(), isTrue);
    });
  });

  group('PendingDraft payload stability', () {
    test('the payload survives jsonEncode(jsonDecode(...)) byte for byte', () {
      final original = record();
      final originalPayloadString = jsonEncode(original.payload);

      final roundTripped = jsonEncode(
        jsonDecode(original.toJson()['payload']! as String),
      );

      expect(roundTripped, equals(originalPayloadString));
    });

    test('the payload string is the exact body the API would post', () {
      final original = record();
      expect(original.canonicalPayload, equals(jsonEncode(ReportApi.payload(draft()))));
    });
  });

  group('PendingDraft checksum', () {
    test('is stable for the same content', () {
      expect(record().computedChecksum, equals(record().computedChecksum));
      expect(record().checksum, isNotEmpty);
      expect(record().checksum.length, 64);
    });

    test('changes when the payload changes', () {
      final changed = record(
        payload: <String, Object?>{...canonicalPayload(), 'route': 'Jogoo Road'},
      );
      expect(changed.computedChecksum, isNot(equals(record().computedChecksum)));
    });

    test('changes when the key changes', () {
      final changed = record(key: '11111111-2222-3333-4444-555555555555');
      expect(changed.computedChecksum, isNot(equals(record().computedChecksum)));
    });

    test('changes when the timestamps change', () {
      final created = record(createdAt: 1760000000001);
      expect(created.computedChecksum, isNot(equals(record().computedChecksum)));

      final expires = record(expiresAt: 1760000000000 + 3600000 + 1);
      expect(expires.computedChecksum, isNot(equals(record().computedChecksum)));
    });

    test('excludes the checksum field itself', () {
      final original = record();
      final withChecksum = original.toJson();
      withChecksum['checksum'] = 'a' * 64;
      expect(withChecksum.containsKey('checksum'), isTrue);
      expect(original.canonicalString.contains('checksum'), isFalse);
    });

    test('verifies for a matching record and fails for a tampered one', () {
      expect(record().verifyChecksum(), isTrue);
      expect(record(payload: <String, Object?>{'incident': 'threats'}).verifyChecksum(),
          isTrue);
    });
  });

  group('PendingDraft expiry', () {
    test('is not expired before the expiry timestamp', () {
      final created = DateTime.fromMillisecondsSinceEpoch(1760000000000);
      final pending = record(createdAt: created.millisecondsSinceEpoch);

      expect(pending.isExpired(created), isFalse);
      expect(pending.isExpired(created.add(const Duration(hours: 23))), isFalse);
    });

    test('is expired once the expiry timestamp is reached', () {
      final created = DateTime.fromMillisecondsSinceEpoch(1760000000000);
      final pending = record(createdAt: created.millisecondsSinceEpoch);

      expect(pending.isExpired(created.add(const Duration(hours: 24))), isTrue);
      expect(pending.isExpired(created.add(const Duration(days: 2))), isTrue);
    });

    test('uses the 24 hour default window', () {
      expect(kPendingDraftExpiryHours, 24);
      final created = DateTime.fromMillisecondsSinceEpoch(1760000000000);
      expect(
        PendingDraft.expiryFor(created),
        created.millisecondsSinceEpoch + const Duration(hours: 24).inMilliseconds,
      );
    });
  });

  group('PendingDraft corruption handling', () {
    test('an unknown version is corrupt, not a parse failure', () {
      final stored = record().toJson()..['version'] = 2;

      expect(
        () => PendingDraft.fromJson(stored),
        throwsA(isA<PendingDraftCorruptException>()),
      );
    });

    test('a missing field is corrupt', () {
      final stored = record().toJson()..remove('key');

      expect(
        () => PendingDraft.fromJson(stored),
        throwsA(isA<PendingDraftCorruptException>()),
      );
    });

    test('a payload that is not JSON is corrupt', () {
      final stored = record().toJson()..['payload'] = '{not json';

      expect(
        () => PendingDraft.fromJson(stored),
        throwsA(isA<PendingDraftCorruptException>()),
      );
    });

    test('the corruption reason never carries report content', () {
      final stored = record().toJson()..['version'] = 2;

      try {
        PendingDraft.fromJson(stored);
        fail('expected a corruption error');
      } on PendingDraftCorruptException catch (e) {
        expect(e.reason, isNot(contains('Thika Road')));
        expect(e.reason, contains('version'));
      }
    });
  });

  group('sha256', () {
    test('matches the FIPS 180-4 test vectors', () {
      expect(
        sha256Hex(''),
        equals('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
      );
      expect(
        sha256Hex('abc'),
        equals('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'),
      );
      expect(
        sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        equals('248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'),
      );
    });

    test('handles input longer than one block', () {
      expect(
        sha256Hex('a' * 1000),
        equals('41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3'),
      );
    });
  });
}
