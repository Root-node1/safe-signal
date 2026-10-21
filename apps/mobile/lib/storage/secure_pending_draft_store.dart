import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pending_draft.dart';
import 'pending_draft_store.dart';

/// The single storage key the pending record lives under (SR-3.1).
const String kPendingDraftStorageKey = 'safesignal_pending_draft_v1';

/// A stored record that cannot be trusted. Same type as the one `PendingDraft`
/// raises, so a corrupt record has one name wherever it is detected. T-13 builds
/// the full exception hierarchy on top of it.
typedef PendingDraftCorrupt = PendingDraftCorruptException;

/// The platform keystore or storage failed. This is not a corrupt record: the
/// stored value may be perfectly good, it just could not be read or written now.
/// [reason] never contains report content, the key or a stored value. T-13
/// refines this into the specified hierarchy.
class PendingDraftStorageException implements Exception {
  const PendingDraftStorageException(this.reason);

  final String reason;

  @override
  String toString() => 'PendingDraftStorageException: $reason';
}

/// The smallest string key-value surface the store needs. The real
/// implementation is [FlutterSecureKeyValue]; unit tests use a fake.
abstract class SecureKeyValue {
  /// The value for [key], or `null` when absent. Throws on platform failure.
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  /// Removes [key]. Succeeds when it is absent.
  Future<void> delete(String key);
}

/// [SecureKeyValue] over `flutter_secure_storage`.
///
/// On Android the plugin's default `AndroidOptions()` encrypts each value with
/// AES-GCM; that AES key is wrapped with an RSA-OAEP key held in the Android
/// Keystore. No key material is handled by the app (SR-3.3, SR-12.2).
class FlutterSecureKeyValue implements SecureKeyValue {
  FlutterSecureKeyValue([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// [PendingDraftStore] over a keystore-backed [SecureKeyValue].
///
/// The whole record is one JSON value under [kPendingDraftStorageKey], so a torn
/// write cannot leave a partial record (RR-4.1). It never falls back to plaintext
/// storage: when the keystore fails, [isAvailable] is `false` and operations
/// throw [PendingDraftStorageException].
class SecurePendingDraftStore implements PendingDraftStore {
  SecurePendingDraftStore([SecureKeyValue? storage])
      : _storage = storage ?? FlutterSecureKeyValue();

  final SecureKeyValue _storage;

  @override
  Future<bool> isAvailable() async {
    try {
      // A read is non-destructive and forces the keystore to initialise.
      await _storage.read(kPendingDraftStorageKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PendingDraft?> read() async {
    final String? raw;
    try {
      raw = await _storage.read(kPendingDraftStorageKey);
    } catch (e) {
      throw PendingDraftStorageException('read failed (${e.runtimeType})');
    }
    if (raw == null) return null;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const PendingDraftCorrupt('record is not an object');
      }
      final record = PendingDraft.fromJson(decoded.cast<String, Object?>());
      // Touch the lazily cast payload and check integrity inside this guard.
      if (!record.verifyChecksum()) {
        throw const PendingDraftCorrupt('checksum does not match');
      }
      return record;
    } on PendingDraftCorrupt {
      rethrow;
    } on FormatException {
      throw const PendingDraftCorrupt('record is not valid JSON');
    } on TypeError {
      throw const PendingDraftCorrupt('record has an unexpected structure');
    }
  }

  @override
  Future<void> write(PendingDraft draft) async {
    final String value = jsonEncode(draft.toJson());
    try {
      await _storage.write(kPendingDraftStorageKey, value);
    } catch (e) {
      throw PendingDraftStorageException('write failed (${e.runtimeType})');
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(kPendingDraftStorageKey);
    } catch (e) {
      throw PendingDraftStorageException('delete failed (${e.runtimeType})');
    }
  }
}
