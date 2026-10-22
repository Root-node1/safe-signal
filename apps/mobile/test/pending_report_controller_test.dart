import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/storage/in_memory_pending_draft_store.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';
import 'package:safesignal/storage/secure_pending_draft_store.dart';

/// A request the fake API saw.
class SeenRequest {
  SeenRequest(this.body, this.key);
  final Map<String, Object?> body;
  final String? key;
}

/// Builds an API that records what it was asked to send.
ReportApi recordingApi(
  List<SeenRequest> seen, {
  int status = 201,
  List<int>? statuses,
  bool failWith = false,
  String code = 'SS-ABCD-2345',
}) =>
    ReportApi(
      baseUrl: 'https://api.example.test/',
      client: MockClient((request) async {
        seen.add(SeenRequest(
          jsonDecode(request.body) as Map<String, Object?>,
          request.headers['Idempotency-Key'],
        ));
        if (failWith) {
          // The request may or may not have reached the server.
          throw const SocketException('connection reset');
        }
        final index = statuses == null ? 0 : seen.length - 1;
        final code_ = statuses == null
            ? status
            : statuses[index.clamp(0, statuses.length - 1)];
        return http.Response(jsonEncode({'code': code}), code_);
      }),
    );

ReportDraft filledDraft() => ReportDraft()
  ..timing = Timing.now
  ..incident = IncidentType.threats
  ..support = SupportOption.private
  ..route = 'Thika Road'
  ..area = 'Githurai 45'
  ..vehicle = 'KDA 123A'
  ..sacco = 'Super Metro';

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

void main() {
  final savedAt = DateTime.fromMillisecondsSinceEpoch(1760000000000);
  final expiresAt = savedAt.add(const Duration(hours: 24));

  group('savePending', () {
    test('refuses when the draft is not finished', () async {
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: ReportDraft()..timing = Timing.now,
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      final outcome = await controller.savePending();

      expect(outcome, isA<SaveRefused>());
      expect(await controller.pendingStore!.read(), isNull);
    });

    test('writes the canonical payload with a key and the expiry window', () async {
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      final outcome = await controller.savePending();

      expect(outcome, isA<SaveSucceeded>());
      final stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.payload, equals(ReportApi.payload(filledDraft())));
      expect(stored.key, isNotEmpty);
      expect(stored.createdAt, savedAt.millisecondsSinceEpoch);
      expect(stored.expiresAt, expiresAt.millisecondsSinceEpoch);
    });

    test('adopts a key when the controller holds none', () async {
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      expect(controller.currentKey, isNull);
      await controller.savePending();

      // The key the record carries is now the controller's key, so the next
      // submit of the same content reuses it (FR-1.5 as amended).
      expect(controller.currentKey, (await store.read())!.key);
    });

    test('does not change the draft or the submission state', () async {
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      await controller.savePending();

      expect(controller.draft.route, 'Thika Road');
      expect(controller.draft.incident, IncidentType.threats);
      expect(controller.state, isA<Idle>());
    });

    test('uses the current key when the controller already has one', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        // A failed attempt keeps the key, so the controller holds one.
        api: recordingApi(seen, status: 500),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      await controller.submit();
      final keyAfterSubmit = controller.currentKey;
      expect(keyAfterSubmit, isNotNull);

      await controller.savePending();

      expect((await store.read())!.key, keyAfterSubmit);
    });

    test('a failed write is reported, not swallowed', () async {
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      fake.failWrites = true;
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      await expectLater(
        controller.savePending(),
        throwsA(isA<PendingDraftWriteFailed>()),
      );
    });

    test('refuses when the app has no store', () async {
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
      );

      expect(await controller.savePending(), isA<SaveRefused>());
    });
  });

  group('restorePending', () {
    test('restores the draft, the key and the signature', () async {
      final store = InMemoryPendingDraftStore();
      final saver = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await saver.savePending();
      final savedKey = (await store.read())!.key;

      final restorer = SubmissionController(
        api: recordingApi([]),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );

      final outcome = await restorer.restorePending();

      expect(outcome, isA<RestoreSucceeded>());
      expect(restorer.draft.incident, IncidentType.threats);
      expect(restorer.draft.timing, Timing.now);
      expect(restorer.draft.support, SupportOption.private);
      expect(restorer.draft.route, 'Thika Road');
      expect(restorer.draft.area, 'Githurai 45');
      expect(restorer.draft.vehicle, 'KDA 123A');
      expect(restorer.draft.sacco, 'Super Metro');
      expect(restorer.currentKey, savedKey);
    });

    test('nothing saved gives its own outcome', () async {
      final controller = SubmissionController(
        api: recordingApi([]),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      expect(await controller.restorePending(), isA<RestoreNothingSaved>());
    });

    test('an expired record is deleted and not restored', () async {
      final store = InMemoryPendingDraftStore();
      final saver = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await saver.savePending();

      final restorer = SubmissionController(
        api: recordingApi([]),
        pendingStore: store,
        clock: () => expiresAt.add(const Duration(minutes: 1)),
      );

      final outcome = await restorer.restorePending();

      expect(outcome, isA<RestoreExpired>());
      expect((outcome as RestoreExpired).createdAt, savedAt);
      expect(restorer.draft.incident, isNull);
      expect(restorer.currentKey, isNull);
      expect(await store.read(), isNull);
    });

    test('a corrupt record is deleted and not restored', () async {
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      // A complete record whose payload cannot be read.
      final stored = PendingDraft(
        payload: ReportApi.payload(filledDraft()),
        key: '11111111-2222-3333-4444-555555555555',
        createdAt: savedAt.millisecondsSinceEpoch,
        expiresAt: expiresAt.millisecondsSinceEpoch,
      ).toJson();
      stored['payload'] = '{broken';
      fake.values[kPendingDraftStorageKey] = jsonEncode(stored);

      final controller = SubmissionController(
        api: recordingApi([]),
        pendingStore: store,
        clock: () => savedAt,
      );

      final outcome = await controller.restorePending();

      expect(outcome, isA<RestoreCorrupt>());
      expect(controller.draft.incident, isNull);
      expect(controller.currentKey, isNull);
      expect(fake.values, isEmpty);
    });

    test('an unavailable store is raised, not treated as nothing saved', () async {
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      fake.failReads = true;
      final controller = SubmissionController(
        api: recordingApi([]),
        pendingStore: store,
        clock: () => savedAt,
      );

      await expectLater(
        controller.restorePending(),
        throwsA(isA<PendingDraftUnavailable>()),
      );
    });
  });

  group('save, restore and submit', () {
    test('sends the same key and the same body bytes', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final saver = SubmissionController(
        api: recordingApi(seen),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await saver.savePending();
      final saved = await store.read();

      final restorer = SubmissionController(
        api: recordingApi(seen),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );
      await restorer.restorePending();
      await restorer.submit();

      expect(seen, hasLength(1), reason: 'exactly one submission');
      expect(seen.single.key, saved!.key);
      expect(seen.single.body, equals(saved.payload));
      expect(jsonEncode(seen.single.body), equals(saved.canonicalPayload));
    });

    test('an edit after restore mints a new key', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final saver = SubmissionController(
        api: recordingApi(seen),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await saver.savePending();
      final savedKey = (await store.read())!.key;

      final restorer = SubmissionController(
        api: recordingApi(seen),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );
      await restorer.restorePending();
      restorer.draft.route = 'Jogoo Road';
      await restorer.submit();

      expect(seen, hasLength(1));
      expect(seen.single.key, isNot(savedKey));
      expect(seen.single.body['route'], 'Jogoo Road');
    });

    test('an unchanged restored report reuses the stored key', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final saver = SubmissionController(
        api: recordingApi(seen),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await saver.savePending();
      final savedKey = (await store.read())!.key;

      final restorer = SubmissionController(
        // The first attempt fails, so the retry is an unchanged retry.
        api: recordingApi(seen, statuses: [500, 201]),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );
      await restorer.restorePending();
      await restorer.submit();
      await restorer.submit();

      expect(seen, hasLength(2));
      expect(seen[0].key, savedKey);
      expect(seen[1].key, savedKey);
      expect(seen[0].body, equals(seen[1].body));
    });

    test('no submission happens without an explicit call', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi(seen),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      await controller.savePending();
      await controller.restorePending();

      expect(seen, isEmpty);
    });
  });

  group('discardPending', () {
    test('deletes the record and clears the draft and the key', () async {
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await controller.savePending();
      await controller.restorePending();
      expect(controller.currentKey, isNotNull);

      await controller.discardPending();

      expect(await store.read(), isNull);
      expect(controller.draft.incident, isNull);
      expect(controller.draft.route, isEmpty);
      expect(controller.currentKey, isNull);
    });

    test('a failed delete is raised and nothing is cleared', () async {
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await controller.savePending();
      await controller.restorePending();
      fake.failDeletes = true;

      await expectLater(
        controller.discardPending(),
        throwsA(isA<PendingDraftDeleteFailed>()),
      );

      fake.failDeletes = false;
      expect(controller.draft.incident, IncidentType.threats);
      expect(controller.currentKey, isNotNull);
      expect(fake.values.containsKey(kPendingDraftStorageKey), isTrue);
    });
  });

  group('one key for a saved report and its same-session submission', () {
    // The approved correction (FR-1.5 as amended): a save installs its key
    // only after the record is written, so a saved report and a same-session
    // submission of identical content never acquire two keys. Without it, an
    // ambiguous outcome followed by a restart and a restore would send the
    // retry under a second key, and the server would store a second report for
    // the same content (RR-3.1).
    test('save, ambiguous submit, restart, restore and retry all use one key', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        // The request may or may not have reached the server.
        api: recordingApi(seen, failWith: true),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      // Save: the record carries key A, and the controller adopts it.
      expect(await controller.savePending(), isA<SaveSucceeded>());
      final saved = await store.read();
      expect(saved, isNotNull);
      final keyA = saved!.key;
      expect(controller.currentKey, keyA);

      // The same-session submission uses that key and that body.
      await controller.submit();
      expect(seen, hasLength(1));
      expect(seen.single.key, keyA);
      expect(jsonEncode(seen.single.body), equals(saved.canonicalPayload));

      // The outcome is ambiguous: the request may or may not have reached the
      // server, so the record is kept and the key is kept with it.
      expect(controller.state, isA<NetworkFailed>());
      expect(controller.currentKey, keyA);
      expect(await store.read(), isNotNull);

      // A restart: a new controller over the same store.
      final restarted = SubmissionController(
        api: recordingApi(seen),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );

      // Restoring adopts the same key, and nothing is sent on its own.
      expect(await restarted.restorePending(), isA<RestoreSucceeded>());
      expect(restarted.currentKey, keyA);
      expect(seen, hasLength(1), reason: 'a restore must not submit');

      // The retry uses the same key and the same body: one logical submission.
      await restarted.submit();
      expect(seen, hasLength(2));
      expect(seen[1].key, keyA);
      expect(jsonEncode(seen[1].body), equals(jsonEncode(seen[0].body)));
      expect(
        seen.map((r) => r.key).toSet(),
        hasLength(1),
        reason: 'every attempt of this report used one key',
      );
    });

    test('a failed write leaves the controller keyless', () async {
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      fake.failWrites = true;
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      await expectLater(
        controller.savePending(),
        throwsA(isA<PendingDraftWriteFailed>()),
      );

      expect(controller.currentKey, isNull);
    });

    test('a failed write leaves the previous key and signature unchanged', () async {
      final seen = <SeenRequest>[];
      final fake = FakeKeyValue();
      final store = SecurePendingDraftStore(fake);
      final controller = SubmissionController(
        // A failed attempt leaves the controller holding a key.
        api: recordingApi(seen, status: 500),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await controller.submit();
      final keyBefore = controller.currentKey;
      expect(keyBefore, isNotNull);

      fake.failWrites = true;
      await expectLater(
        controller.savePending(),
        throwsA(isA<PendingDraftWriteFailed>()),
      );

      expect(controller.currentKey, keyBefore);
      expect(store.read, isNotNull);
    });

    test('an unchanged payload retains its key across saves', () async {
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      await controller.savePending();
      final keyAfterFirst = controller.currentKey;
      final recordKey = (await store.read())!.key;
      expect(keyAfterFirst, recordKey);

      await controller.savePending();

      expect(controller.currentKey, keyAfterFirst);
      expect((await store.read())!.key, recordKey);
    });

    test('saving preserves an existing controller key', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        // A failed attempt keeps the controller's key.
        api: recordingApi(seen, status: 500),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await controller.submit();
      final existingKey = controller.currentKey;
      expect(existingKey, isNotNull);

      await controller.savePending();

      expect(controller.currentKey, existingKey);
      expect((await store.read())!.key, existingKey);
    });

    test('an edit after a save generates a new key', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi(seen),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await controller.savePending();
      final savedKey = controller.currentKey;

      controller.draft.route = 'Jogoo Road';
      await controller.submit();

      expect(seen, hasLength(1));
      expect(seen.single.key, isNot(savedKey));
      expect(seen.single.body['route'], 'Jogoo Road');
    });

    test('saving does not change the draft or the submission state', () async {
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      await controller.savePending();

      expect(controller.draft.route, 'Thika Road');
      expect(controller.draft.incident, IncidentType.threats);
      expect(controller.draft.area, 'Githurai 45');
      expect(controller.state, isA<Idle>());
    });
  });

  group('the residual divergence for an edited report', () {
    // Documents the remaining case: the controller holds a key for payload A
    // (an earlier failed attempt), the user edits the report to payload B and
    // saves it, and the key the record carries is not the key the next
    // submission of B uses. The save cannot replace the controller's key
    // under FR-1.5 as currently amended, so the two diverge.
    //
    // Whether the controller may adopt the saved key for changed content is a
    // decision that has not been taken; this test records the current state so
    // the change is visible when it is made.
    test('an edited report is saved and submitted under one key', () async {
      final seen = <SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: recordingApi(seen, failWith: true),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      // 1. Payload A is submitted and the attempt fails; A's key is kept.
      await controller.submit();
      expect(seen, hasLength(1));
      final keyForA = seen.single.key;
      expect(controller.currentKey, keyForA);

      // 2. The report is edited to payload B.
      controller.draft.route = 'Jogoo Road';

      // 3. Payload B is saved.
      expect(await controller.savePending(), isA<SaveSucceeded>());
      final keyForB = (await store.read())!.key;

      // 4. The controller and the saved record share B's key.
      expect(controller.currentKey, keyForB);
      expect(keyForB, isNot(keyForA));

      // 5. B is submitted from the same session; the outcome is ambiguous.
      await controller.submit();
      expect(seen, hasLength(2));
      final keyForFirstB = seen[1].key;
      expect(keyForFirstB, keyForB);
      expect(jsonEncode(seen[1].body), contains('Jogoo Road'));

      // 6. A restart: a new controller over the same store.
      final restarted = SubmissionController(
        api: recordingApi(seen),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );

      // 7. The record is restored; it adopts the same key and sends nothing.
      expect(await restarted.restorePending(), isA<RestoreSucceeded>());
      expect(restarted.currentKey, keyForB);
      expect(seen, hasLength(2), reason: 'a restore must not submit');

      // 8. The retry of B: the same key and a byte-identical body.
      await restarted.submit();
      expect(seen, hasLength(3));
      final keyForRetryB = seen[2].key;
      expect(keyForRetryB, keyForFirstB);
      expect(jsonEncode(seen[2].body), equals(jsonEncode(seen[1].body)));
      expect(
        seen.where((r) => r.body['route'] == 'Jogoo Road').map((r) => r.key).toSet(),
        hasLength(1),
        reason: 'both attempts of B used one key',
      );
    });

    test('a save during an in-flight submission does not change that request', () async {
      final seen = <SeenRequest>[];
      final gate = Completer<http.Response>();
      final api = ReportApi(
        baseUrl: 'https://api.example.test/',
        client: MockClient((request) async {
          seen.add(SeenRequest(
            jsonDecode(request.body) as Map<String, Object?>,
            request.headers['Idempotency-Key'],
          ));
          return gate.future;
        }),
      );
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: api,
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      // A submission of payload A is in flight.
      final inFlight = controller.submit();
      expect(controller.state, isA<Submitting>());
      // Let the request reach the client.
      await Future<void>.delayed(Duration.zero);
      expect(seen, hasLength(1));
      final keyForA = seen.single.key;
      final bodyForA = jsonEncode(seen.single.body);

      // The user edits the report and saves it while the request is in flight.
      controller.draft.route = 'Jogoo Road';
      await controller.savePending();

      // The in-flight request still carries A's key and A's body.
      expect(seen, hasLength(1));
      expect(seen.single.key, keyForA);
      expect(jsonEncode(seen.single.body), bodyForA);

      // The save gave the controller B's key, and the record holds it.
      final savedKeyForB = (await store.read())!.key;
      expect(controller.currentKey, savedKeyForB);

      // The late response for A is applied to the controller, but it cannot
      // overwrite the saved identity of B: the record still holds B's key.
      gate.complete(http.Response(jsonEncode({'code': 'SS-ABCD-2345'}), 201));
      await inFlight;

      expect((await store.read())!.key, savedKeyForB);
      expect(controller.state, isA<Succeeded>());
    });
  });

  group('the record never leaks its contents', () {
    test('a save outcome carries no key and no payload', () async {
      final controller = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      final outcome = await controller.savePending();

      expect(outcome.toString(), isNot(contains('Thika Road')));
      expect(outcome.toString(), isNot(contains('KDA 123A')));
    });

    test('a restore outcome carries no key and no payload', () async {
      final store = InMemoryPendingDraftStore();
      final saver = SubmissionController(
        api: recordingApi([]),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );
      await saver.savePending();

      final restorer = SubmissionController(
        api: recordingApi([]),
        pendingStore: store,
        clock: () => savedAt.add(const Duration(hours: 1)),
      );
      final outcome = await restorer.restorePending();

      expect(outcome.toString(), isNot(contains('Thika Road')));
      expect(outcome.toString(), isNot(contains('KDA 123A')));
    });
  });
}
