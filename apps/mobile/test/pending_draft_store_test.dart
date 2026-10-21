import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/storage/in_memory_pending_draft_store.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';

PendingDraft record({String key = 'key-1', int createdAt = 1760000000000}) {
  final draft = ReportDraft()
    ..timing = Timing.now
    ..incident = IncidentType.threats
    ..support = SupportOption.private
    ..route = 'Thika Road';
  return PendingDraft(
    payload: ReportApi.payload(draft),
    key: key,
    createdAt: createdAt,
    expiresAt: PendingDraft.expiryFor(
      DateTime.fromMillisecondsSinceEpoch(createdAt),
    ),
  );
}

/// The contract any [PendingDraftStore] must satisfy.
void storeContract(PendingDraftStore Function() create) {
  late PendingDraftStore store;
  setUp(() => store = create());

  test('read returns null when nothing is stored', () async {
    expect(await store.read(), isNull);
  });

  test('write then read returns the same record', () async {
    final saved = record();
    await store.write(saved);
    final loaded = await store.read();
    expect(loaded, isNotNull);
    expect(loaded!.key, saved.key);
    expect(loaded.canonicalPayload, saved.canonicalPayload);
    expect(loaded.createdAt, saved.createdAt);
    expect(loaded.expiresAt, saved.expiresAt);
  });

  test('a stored record keeps a verifying checksum', () async {
    await store.write(record());
    expect((await store.read())!.verifyChecksum(), isTrue);
  });

  test('write replaces the existing record', () async {
    await store.write(record(key: 'first'));
    await store.write(record(key: 'second'));
    expect((await store.read())!.key, 'second');
  });

  test('delete removes the record', () async {
    await store.write(record());
    await store.delete();
    expect(await store.read(), isNull);
  });

  test('delete is idempotent', () async {
    await store.delete();
    await store.delete();
    await store.write(record());
    await store.delete();
    await store.delete();
    expect(await store.read(), isNull);
  });

  test('a record can be written again after delete', () async {
    await store.write(record(key: 'a'));
    await store.delete();
    await store.write(record(key: 'b'));
    expect((await store.read())!.key, 'b');
  });

  test('isAvailable reports true for a usable store', () async {
    expect(await store.isAvailable(), isTrue);
  });
}

void main() {
  group('InMemoryPendingDraftStore contract', () {
    storeContract(() => InMemoryPendingDraftStore());
  });

  group('InMemoryPendingDraftStore behaviour', () {
    test('instances do not share records', () async {
      final a = InMemoryPendingDraftStore();
      final b = InMemoryPendingDraftStore();
      await a.write(record());
      expect(await b.read(), isNull);
    });

    test('a new instance starts empty (nothing is persisted)', () async {
      final first = InMemoryPendingDraftStore();
      await first.write(record());
      expect(await InMemoryPendingDraftStore().read(), isNull);
    });

    test('is usable as a PendingDraftStore only', () {
      final PendingDraftStore store = InMemoryPendingDraftStore();
      expect(store, isA<PendingDraftStore>());
    });
  });

  group('release-build guard', () {
    test('refuses a release build with no reason', () {
      expect(
        () => InMemoryPendingDraftStore(isReleaseBuild: true),
        throwsStateError,
      );
    });

    test('refuses a release build with a blank reason', () {
      expect(
        () => InMemoryPendingDraftStore(isReleaseBuild: true, releaseReason: '  '),
        throwsStateError,
      );
    });

    test('allows a release build with a reason and logs it', () {
      final logs = <String>[];
      InMemoryPendingDraftStore(
        isReleaseBuild: true,
        releaseReason: 'keystore unavailable',
        log: logs.add,
      );
      expect(logs, hasLength(1));
      expect(logs.single, contains('keystore unavailable'));
    });

    test('a non-release build needs no reason and logs nothing', () {
      final logs = <String>[];
      InMemoryPendingDraftStore(isReleaseBuild: false, log: logs.add);
      expect(logs, isEmpty);
    });

    test('the log never contains report content', () async {
      final logs = <String>[];
      final store = InMemoryPendingDraftStore(
        isReleaseBuild: true,
        releaseReason: 'keystore unavailable',
        log: logs.add,
      );
      await store.write(record());
      expect(logs.join(), isNot(contains('Thika Road')));
    });
  });
}
