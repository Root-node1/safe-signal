import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/storage/in_memory_pending_draft_store.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';
import 'package:safesignal/storage/secure_pending_draft_store.dart';

import 'pending_draft_store_test.dart' show record;

/// A keystore stand-in whose read, write and delete each fail on demand.
class FakeKeyValue implements SecureKeyValue {
  final Map<String, String> values = {};
  bool failReads = false;
  bool failWrites = false;
  bool failDeletes = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('keystore unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('keystore write failed');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('keystore delete failed');
    values.remove(key);
  }
}

/// A store whose read, write and delete each fail on demand, and whose read
/// can be scripted to hand back anything at all. It exists to prove that the
/// behaviour lives in the interface, not in one implementation (T-13).
class ScriptedStore implements PendingDraftStore {
  PendingDraft? stored;
  Object? readError;
  Object? writeError;
  Object? deleteError;
  bool available = true;
  int deleteCount = 0;
  int writeCount = 0;

  @override
  Future<PendingDraft?> read() async {
    if (readError != null) throw readError!;
    return stored;
  }

  @override
  Future<void> write(PendingDraft draft) async {
    if (writeError != null) throw writeError!;
    writeCount++;
    stored = draft;
  }

  @override
  Future<void> delete() async {
    deleteCount++;
    if (deleteError != null) throw deleteError!;
    stored = null;
  }

  @override
  Future<bool> isAvailable() async => available;
}

/// A record whose stored checksum does not match its content.
PendingDraft tamperedRecord() => PendingDraft(
      payload: record().payload,
      key: record().key,
      createdAt: record().createdAt,
      expiresAt: record().expiresAt,
      storedChecksum: '0' * 64,
    );

void main() {
  group('exception hierarchy', () {
    test('every store failure shares one base type', () {
      expect(const PendingDraftCorrupt('a'), isA<PendingDraftStoreException>());
      expect(const PendingDraftUnavailable('a'), isA<PendingDraftStoreException>());
      expect(const PendingDraftWriteFailed('a'), isA<PendingDraftStoreException>());
      expect(const PendingDraftDeleteFailed('a'), isA<PendingDraftStoreException>());
    });

    test('an unavailable store is not a corrupt record', () {
      expect(
        const PendingDraftUnavailable('a'),
        isNot(isA<PendingDraftCorrupt>()),
      );
    });

    test('a failure can carry the failure that led to it', () {
      const cause = PendingDraftCorrupt('checksum does not match');
      const failure = PendingDraftDeleteFailed('could not delete', cause: cause);
      expect(failure.cause, same(cause));
    });
  });

  group('readOrDiscard with a healthy store', () {
    test('a missing record reads as absent, not as a failure', () async {
      final store = ScriptedStore();
      expect(await store.readOrDiscard(), isNull);
    });

    test('a valid record is returned unchanged', () async {
      final store = ScriptedStore();
      final saved = record();
      await store.write(saved);

      final loaded = await store.readOrDiscard();
      expect(loaded, isNotNull);
      expect(loaded!.key, saved.key);
      expect(loaded.canonicalPayload, saved.canonicalPayload);
    });

    test('a valid record is not deleted', () async {
      final store = ScriptedStore();
      await store.write(record());
      await store.readOrDiscard();
      expect(store.deleteCount, 0);
      expect(store.stored, isNotNull);
    });
  });

  group('readOrDiscard with a corrupt record', () {
    late FakeKeyValue fake;
    late SecurePendingDraftStore store;

    setUp(() {
      fake = FakeKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    Future<void> seedRaw(String value) async {
      fake.values[kPendingDraftStorageKey] = value;
    }

    Future<void> seedJson(Object? Function(Map<String, Object?> json) edit) async {
      final json = record().toJson();
      final edited = edit(json);
      fake.values[kPendingDraftStorageKey] =
          edited is String ? edited : jsonEncode(edited);
    }

    test('corrupted JSON is discarded and reported', () async {
      await seedRaw('{not json');

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftCorrupt>()),
      );
      expect(fake.values, isEmpty, reason: 'the corrupt record must be deleted');
    });

    test('an unsupported version is discarded and reported', () async {
      await seedJson((j) => j..['version'] = 2);

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftCorrupt>()),
      );
      expect(fake.values, isEmpty);
    });

    test('a checksum mismatch is discarded and reported', () async {
      await seedJson((j) => j..['checksum'] = '0' * 64);

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftCorrupt>()),
      );
      expect(fake.values, isEmpty);
    });

    test('a corrupt record is never returned to the caller', () async {
      await seedJson((j) => j..['checksum'] = '0' * 64);

      PendingDraft? returned;
      try {
        returned = await store.readOrDiscard();
      } on PendingDraftCorrupt {
        returned = null;
      }
      expect(returned, isNull);
    });

    test('a discarded record leaves the store empty', () async {
      await seedJson((j) => j..['checksum'] = '0' * 64);
      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftCorrupt>()),
      );

      expect(await store.read(), isNull);
    });

    test('the corruption reason never carries report content', () async {
      await seedJson((j) => j..['checksum'] = '0' * 64);

      try {
        await store.readOrDiscard();
        fail('expected corruption');
      } on PendingDraftCorrupt catch (e) {
        expect(e.reason, isNot(contains('Thika Road')));
        expect(e.reason, isNot(contains('key-1')));
        expect(e.reason, isNot(contains('safesignal_pending_draft')));
      }
    });

    test('a record that does not verify is refused by read as well', () async {
      await seedJson((j) => j..['checksum'] = '0' * 64);

      await expectLater(
        store.read(),
        throwsA(isA<PendingDraftCorrupt>()),
      );
    });
  });

  group('storage failures', () {
    late FakeKeyValue fake;
    late SecurePendingDraftStore store;

    setUp(() {
      fake = FakeKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    test('a failed read is unavailable, not corrupt and not absent', () async {
      await store.write(record());
      fake.failReads = true;

      await expectLater(
        store.read(),
        throwsA(isA<PendingDraftUnavailable>()),
      );
      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftUnavailable>()),
      );
    });

    test('a failed read does not delete the stored record', () async {
      await store.write(record());
      fake.failReads = true;

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftUnavailable>()),
      );
      fake.failReads = false;
      expect(fake.values.containsKey(kPendingDraftStorageKey), isTrue);
    });

    test('the store reports itself unavailable when the keystore fails', () async {
      fake.failReads = true;
      expect(await store.isAvailable(), isFalse);
    });

    test('a failed write is a write failure and stores nothing', () async {
      fake.failWrites = true;

      await expectLater(
        store.write(record()),
        throwsA(isA<PendingDraftWriteFailed>()),
      );
      expect(fake.values, isEmpty);
    });

    test('a failed write leaves the previous record intact', () async {
      await store.write(record(key: 'old'));
      fake.failWrites = true;

      await expectLater(
        store.write(record(key: 'new')),
        throwsA(isA<PendingDraftWriteFailed>()),
      );
      fake.failWrites = false;
      expect((await store.read())!.key, 'old');
    });

    test('a failed delete is reported and leaves the record intact', () async {
      await store.write(record());
      fake.failDeletes = true;

      await expectLater(
        store.delete(),
        throwsA(isA<PendingDraftDeleteFailed>()),
      );
      fake.failDeletes = false;
      expect(await store.read(), isNotNull);
    });

    test('a failed delete does not half-delete the record', () async {
      await store.write(record());
      fake.failDeletes = true;

      await expectLater(
        store.delete(),
        throwsA(isA<PendingDraftDeleteFailed>()),
      );
      fake.failDeletes = false;
      final stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.key, 'key-1');
    });

    test('delete is idempotent', () async {
      await store.delete();
      await store.delete();
      await store.write(record());
      await store.delete();
      await store.delete();
      expect(await store.read(), isNull);
    });

    test('storage failures never carry report content or stored values', () async {
      await store.write(record());
      fake.failDeletes = true;

      try {
        await store.delete();
        fail('expected a delete failure');
      } on PendingDraftDeleteFailed catch (e) {
        expect(e.reason, isNot(contains('Thika Road')));
        expect(e.reason, isNot(contains('key-1')));
        expect(e.reason, isNot(contains('safesignal_pending_draft')));
      }
    });
  });

  group('readOrDiscard when the deletion of a corrupt record fails', () {
    test('the deletion failure is reported, not swallowed', () async {
      final store = ScriptedStore()
        ..stored = record()
        ..readError = const PendingDraftCorrupt('checksum does not match')
        ..deleteError = const PendingDraftDeleteFailed('delete failed');

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftDeleteFailed>()),
      );
    });

    test('the corruption is kept as the cause of the deletion failure', () async {
      final store = ScriptedStore()
        ..stored = record()
        ..readError = const PendingDraftCorrupt('checksum does not match')
        ..deleteError = const PendingDraftDeleteFailed('delete failed');

      try {
        await store.readOrDiscard();
        fail('expected a delete failure');
      } on PendingDraftDeleteFailed catch (e) {
        expect(e.cause, isA<PendingDraftCorrupt>());
      }
    });

    test('the record is left in place, not half-deleted', () async {
      final store = ScriptedStore()
        ..stored = record()
        ..readError = const PendingDraftCorrupt('checksum does not match')
        ..deleteError = const PendingDraftDeleteFailed('delete failed');

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftDeleteFailed>()),
      );
      expect(store.deleteCount, 1);
      expect(store.stored, isNotNull);
    });
  });

  group('the in-memory store follows the same rules', () {
    test('it refuses to return a record that does not verify', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(tamperedRecord());

      await expectLater(
        store.read(),
        throwsA(isA<PendingDraftCorrupt>()),
      );
    });

    test('a corrupt record is discarded and reported', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(tamperedRecord());

      await expectLater(
        store.readOrDiscard(),
        throwsA(isA<PendingDraftCorrupt>()),
      );
      expect(await store.read(), isNull);
    });

    test('a valid record is returned and kept', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(record());

      final loaded = await store.readOrDiscard();
      expect(loaded, isNotNull);
      expect(loaded!.key, 'key-1');
    });
  });
}
