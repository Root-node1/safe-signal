import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
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

/// A fixed point in time, used as the injected clock.
DateTime at(int epochMs) => DateTime.fromMillisecondsSinceEpoch(epochMs);

void main() {
  final savedAt = at(1760000000000);
  final expiresAt = savedAt.add(const Duration(hours: 24));

  group('expiry boundary', () {
    late FakeKeyValue fake;
    late SecurePendingDraftStore store;

    setUp(() {
      fake = FakeKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    Future<void> seedRecord({int? createdAt}) async {
      final saved = record(createdAt: createdAt ?? savedAt.millisecondsSinceEpoch);
      await store.write(saved);
    }

    test('a record just inside the window is kept', () async {
      await seedRecord();

      final outcome = await store.readOrDiscardAt(expiresAt.subtract(const Duration(milliseconds: 1)));

      expect(outcome, isA<PendingDraftAvailable>());
      expect(fake.values.containsKey(kPendingDraftStorageKey), isTrue);
    });

    test('a record exactly at the expiry timestamp is expired', () async {
      await seedRecord();

      final outcome = await store.readOrDiscardAt(expiresAt);

      expect(outcome, isA<PendingDraftExpired>());
    });

    test('a record after the expiry timestamp is expired', () async {
      await seedRecord();

      final outcome = await store.readOrDiscardAt(expiresAt.add(const Duration(hours: 1)));

      expect(outcome, isA<PendingDraftExpired>());
    });

    test('the expiry window is still 24 hours', () {
      expect(kPendingDraftExpiryHours, 24);
    });
  });

  group('deleting an expired record', () {
    late FakeKeyValue fake;
    late SecurePendingDraftStore store;

    setUp(() {
      fake = FakeKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    test('an expired record is deleted and reported as expired', () async {
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));

      final outcome = await store.readOrDiscardAt(expiresAt.add(const Duration(minutes: 1)));

      expect(outcome, isA<PendingDraftExpired>());
      expect(fake.values, isEmpty, reason: 'the expired record must be gone');
      expect(await store.read(), isNull);
    });

    test('the expired outcome carries when it was saved, and nothing else', () async {
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));

      final outcome = await store.readOrDiscardAt(expiresAt.add(const Duration(minutes: 1)));

      expect(outcome, isA<PendingDraftExpired>());
      final expired = outcome as PendingDraftExpired;
      expect(expired.createdAt, savedAt);
      // The expired content is never carried forward.
      expect(expired.toString(), isNot(contains('Thika Road')));
      expect(expired.toString(), isNot(contains('key-1')));
    });

    test('a failed deletion is reported and leaves the record in place', () async {
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      fake.failDeletes = true;

      await expectLater(
        store.readOrDiscardAt(expiresAt.add(const Duration(minutes: 1))),
        throwsA(isA<PendingDraftDeleteFailed>()),
      );

      fake.failDeletes = false;
      expect(fake.values.containsKey(kPendingDraftStorageKey), isTrue);
    });

    test('a failed deletion of an expired record is not reported as success', () async {
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      fake.failDeletes = true;

      PendingDraftReadOutcome? outcome;
      try {
        outcome = await store.readOrDiscardAt(expiresAt.add(const Duration(minutes: 1)));
      } on PendingDraftDeleteFailed {
        outcome = null;
      }
      expect(outcome, isNull);
    });
  });

  group('the other outcomes stay distinct', () {
    late FakeKeyValue fake;
    late SecurePendingDraftStore store;

    setUp(() {
      fake = FakeKeyValue();
      store = SecurePendingDraftStore(fake);
    });

    test('a missing record is absent, not expired', () async {
      final outcome = await store.readOrDiscardAt(expiresAt.add(const Duration(days: 1)));

      expect(outcome, isA<PendingDraftAbsent>());
      expect(outcome, isNot(isA<PendingDraftExpired>()));
    });

    test('a corrupt record is deleted and reported, not expired', () async {
      final json = record().toJson()..['checksum'] = '0' * 64;
      fake.values[kPendingDraftStorageKey] = jsonEncode(json);

      await expectLater(
        store.readOrDiscardAt(expiresAt.add(const Duration(days: 1))),
        throwsA(isA<PendingDraftCorrupt>()),
      );
      expect(fake.values, isEmpty);
    });

    test('an unavailable store is reported, not treated as absent', () async {
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      fake.failReads = true;

      await expectLater(
        store.readOrDiscardAt(expiresAt.add(const Duration(minutes: 1))),
        throwsA(isA<PendingDraftUnavailable>()),
      );

      fake.failReads = false;
      expect(fake.values.containsKey(kPendingDraftStorageKey), isTrue);
    });
  });

  group('the controller exposes the outcome', () {
    test('an expired record is reported and deleted', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      final controller = SubmissionController(
        api: ReportApi(baseUrl: 'https://api.example.test/'),
        pendingStore: store,
        clock: () => expiresAt.add(const Duration(minutes: 1)),
      );

      final outcome = await controller.readPendingReport();

      expect(outcome, isA<PendingDraftExpired>());
      expect(controller.pendingOutcome, isA<PendingDraftExpired>());
      expect(await store.read(), isNull);
    });

    test('a valid record is available and stays in storage', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      final controller = SubmissionController(
        api: ReportApi(baseUrl: 'https://api.example.test/'),
        pendingStore: store,
        clock: () => expiresAt.subtract(const Duration(minutes: 1)),
      );

      final outcome = await controller.readPendingReport();

      expect(outcome, isA<PendingDraftAvailable>());
      expect((outcome as PendingDraftAvailable).draft.key, 'key-1');
      expect(await store.read(), isNotNull);
    });

    test('no store means nothing to read', () async {
      final controller = SubmissionController(
        api: ReportApi(baseUrl: 'https://api.example.test/'),
      );

      final outcome = await controller.readPendingReport();

      expect(outcome, isA<PendingDraftAbsent>());
    });

    test('the injected clock decides the outcome', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      var now = expiresAt.subtract(const Duration(minutes: 1));
      final controller = SubmissionController(
        api: ReportApi(baseUrl: 'https://api.example.test/'),
        pendingStore: store,
        clock: () => now,
      );

      expect(await controller.readPendingReport(), isA<PendingDraftAvailable>());

      now = expiresAt.add(const Duration(minutes: 1));
      expect(await controller.readPendingReport(), isA<PendingDraftExpired>());
    });

    test('reading the pending report does not touch the draft or the key', () async {
      final store = InMemoryPendingDraftStore();
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      final controller = SubmissionController(
        api: ReportApi(baseUrl: 'https://api.example.test/'),
        pendingStore: store,
        clock: () => expiresAt.add(const Duration(minutes: 1)),
      );

      await controller.readPendingReport();

      expect(controller.draft.incident, isNull);
      expect(controller.draft.support, isNull);
      expect(controller.currentKey, isNull);
    });

    test('a failed deletion during startup is caught, not rethrown', () async {
      // This test needs a SecurePendingDraftStore with a failing delete, so it
      // creates its own fake keystore and store rather than relying on a
      // group-level setUp.
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      await store.write(record(createdAt: savedAt.millisecondsSinceEpoch));
      fake.failDeletes = true;

      final expiredController = SubmissionController(
        api: ReportApi(baseUrl: 'https://api.example.test/'),
        pendingStore: store,
        clock: () => expiresAt.add(const Duration(minutes: 1)),
      );

      // Before the fix this threw PendingDraftDeleteFailed and crashed startup.
      final outcome = await expiredController.readPendingReport();

      // The error is cached for the UI, not rethrown.
      expect(outcome, isA<PendingDraftAbsent>());
      expect(
        expiredController.pendingReadError,
        isA<PendingDraftDeleteFailed>(),
        reason: 'the deletion failure must be surfaced, not swallowed (RR-4.3)',
      );

      // The record is still in storage (nothing was half-deleted).
      fake.failDeletes = false;
      expect(fake.values.containsKey(kPendingDraftStorageKey), isTrue);
    });
  });
}
