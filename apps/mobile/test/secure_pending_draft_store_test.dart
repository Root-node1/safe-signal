import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';
import 'package:safesignal/storage/secure_pending_draft_store.dart';

import 'pending_draft_store_test.dart' show record, storeContract;

/// An in-process stand-in for the keystore. It proves the store's logic only,
/// not that anything is encrypted on a device (that is T-31).
class FakeSecureKeyValue implements SecureKeyValue {
  final Map<String, String> values = {};
  bool failReads = false;
  bool failWrites = false;
  bool failDeletes = false;
  int writeCount = 0;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('keystore unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('keystore write failed');
    writeCount++;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('keystore delete failed');
    values.remove(key);
  }
}

void main() {
  group('SecurePendingDraftStore contract', () {
    storeContract(() => SecurePendingDraftStore(FakeSecureKeyValue()));
  });

  group('SecurePendingDraftStore storage', () {
    late FakeSecureKeyValue fake;
    late SecurePendingDraftStore store;
    setUp(() {
      fake = FakeSecureKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    test('uses exactly one storage key', () async {
      await store.write(record(key: 'a'));
      await store.write(record(key: 'b'));
      expect(fake.values.keys, ['safesignal_pending_draft_v1']);
    });

    test('stores the whole record as one JSON value', () async {
      await store.write(record());
      final stored = jsonDecode(fake.values.values.single) as Map;
      expect(stored.keys,
          containsAll(['version', 'payload', 'key', 'createdAt', 'expiresAt', 'checksum']));
    });

    test('delete leaves no value behind', () async {
      await store.write(record());
      await store.delete();
      expect(fake.values, isEmpty);
    });
  });

  group('SecurePendingDraftStore corruption', () {
    late FakeSecureKeyValue fake;
    late SecurePendingDraftStore store;
    setUp(() {
      fake = FakeSecureKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    Future<void> seed(Object? Function(Map<String, Object?> json) edit) async {
      final json = record().toJson();
      final edited = edit(json);
      fake.values[kPendingDraftStorageKey] =
          edited is String ? edited : jsonEncode(edited);
    }

    Future<void> expectCorrupt() =>
        expectLater(store.read(), throwsA(isA<PendingDraftCorrupt>()));

    test('malformed JSON', () async {
      await seed((_) => '{not json');
      await expectCorrupt();
    });

    test('JSON that is not an object', () async {
      await seed((_) => '[1,2,3]');
      await expectCorrupt();
    });

    test('unknown version', () async {
      await seed((j) => j..['version'] = 2);
      await expectCorrupt();
    });

    test('incorrect checksum', () async {
      await seed((j) => j..['checksum'] = '0' * 64);
      await expectCorrupt();
    });

    test('tampered payload', () async {
      await seed((j) {
        final payload = jsonDecode(j['payload']! as String) as Map;
        payload['route'] = 'Somewhere else';
        return j..['payload'] = jsonEncode(payload);
      });
      await expectCorrupt();
    });

    test('tampered key', () async {
      await seed((j) => j..['key'] = 'another-key');
      await expectCorrupt();
    });

    test('payload that is not an object', () async {
      await seed((j) => j..['payload'] = '[1]');
      await expectCorrupt();
    });

    test('payload missing', () async {
      await seed((j) => j..remove('payload'));
      await expectCorrupt();
    });

    test('field of the wrong type', () async {
      await seed((j) => j..['createdAt'] = 'yesterday');
      await expectCorrupt();
    });

    test('payload object with an unexpected inner structure', () async {
      await seed((j) => j..['payload'] = {'a': 1});
      await expectCorrupt();
    });

    test('a corrupt value is never returned as a record', () async {
      await seed((j) => j..['checksum'] = 'bad');
      PendingDraft? got;
      try {
        got = await store.read();
      } on PendingDraftCorrupt {
        got = null;
      }
      expect(got, isNull);
    });

    test('corruption reasons never contain report content', () async {
      await seed((j) => j..['checksum'] = 'bad');
      try {
        await store.read();
        fail('expected corruption');
      } on PendingDraftCorrupt catch (e) {
        expect(e.reason, isNot(contains('Thika Road')));
        expect(e.reason, isNot(contains('key-1')));
      }
    });
  });

  group('SecurePendingDraftStore keystore failures', () {
    late FakeSecureKeyValue fake;
    late SecurePendingDraftStore store;
    setUp(() {
      fake = FakeSecureKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    test('isAvailable is false when the keystore fails', () async {
      fake.failReads = true;
      expect(await store.isAvailable(), isFalse);
    });

    test('isAvailable is non-destructive', () async {
      await store.write(record());
      await store.isAvailable();
      expect((await store.read())!.key, 'key-1');
      expect(fake.writeCount, 1);
    });

    test('a failed read is a storage error, not corruption', () async {
      fake.failReads = true;
      await expectLater(
        store.read(),
        throwsA(isA<PendingDraftStorageException>()),
      );
    });

    test('a failed write is a storage error and stores nothing', () async {
      fake.failWrites = true;
      await expectLater(
        store.write(record()),
        throwsA(isA<PendingDraftStorageException>()),
      );
      expect(fake.values, isEmpty);
    });

    test('a failed write leaves the previous record intact', () async {
      await store.write(record(key: 'old'));
      fake.failWrites = true;
      await expectLater(
        store.write(record(key: 'new')),
        throwsA(isA<PendingDraftStorageException>()),
      );
      fake.failWrites = false;
      expect((await store.read())!.key, 'old');
    });

    test('a failed delete is reported and keeps the record', () async {
      await store.write(record());
      fake.failDeletes = true;
      await expectLater(
        store.delete(),
        throwsA(isA<PendingDraftStorageException>()),
      );
      fake.failDeletes = false;
      expect(await store.read(), isNotNull);
    });

    test('storage errors never contain report content or values', () async {
      fake.failWrites = true;
      try {
        await store.write(record());
        fail('expected a storage error');
      } on PendingDraftStorageException catch (e) {
        expect(e.reason, isNot(contains('Thika Road')));
        expect(e.reason, isNot(contains('key-1')));
      }
    });

    test('is usable as a PendingDraftStore only', () {
      final PendingDraftStore s = SecurePendingDraftStore(fake);
      expect(s, isA<PendingDraftStore>());
    });
  });
}
