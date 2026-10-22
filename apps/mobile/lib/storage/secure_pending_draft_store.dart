import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pending_draft.dart';
import 'pending_draft_store.dart';

/// The single storage key the pending record lives under (SR-3.1).
const String kPendingDraftStorageKey = 'safesignal_pending_draft_v1';

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
/// storage: when the keystore fails, [isAvailable] is `false` and the operations
/// throw the typed failures from `pending_draft_store.dart`.
///
/// **Why an interrupted write is safe (RR-4.1).** Two things together make it
/// safe, and neither is enough on its own:
///
/// 1. *The single-value write.* The whole record is one value, so the platform
///    either has the old value, the new value, or nothing. There is no
///    multi-field state that can be half written, and the record cannot be
///    assembled from pieces of two different writes.
/// 2. *The checksum.* The record carries a SHA-256 over its own content. A value
///    that is present but not the record we intended — a value written by an
///    older app version, or one mangled by a keystore fault — does not verify,
///    so it is treated as corrupt and deleted instead of being restored
///    (SR-4.2, RR-4.2). A restored report is therefore either exactly what was
///    saved or nothing at all.
///
/// Failures are reported by kind: a read that cannot reach the keystore is
/// [PendingDraftUnavailable] and is never treated as "no record"; a write that
/// fails is [PendingDraftWriteFailed]; a delete that fails is
/// [PendingDraftDeleteFailed] and leaves the record intact (RR-4.3).
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
      // The keystore could not be reached. The stored record may be fine: this
      // is not corruption, and it is never reported as an absent record.
      throw PendingDraftUnavailable('read failed (${e.runtimeType})');
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
    } on PendingDraftCorruptException catch (e) {
      // The record itself rejected it: wrong version, missing field, or a
      // payload that is not the expected object.
      throw PendingDraftCorrupt(e.reason);
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
      // Nothing was written: the previous record, if any, is untouched.
      throw PendingDraftWriteFailed('write failed (${e.runtimeType})');
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(kPendingDraftStorageKey);
    } catch (e) {
      // The record is still there. Report the failure; never report success.
      throw PendingDraftDeleteFailed('delete failed (${e.runtimeType})');
    }
  }
}
