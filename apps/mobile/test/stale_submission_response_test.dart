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

/// A request the fake API saw.
class SeenRequest {
  SeenRequest(this.body, this.key);
  final Map<String, Object?> body;
  final String? key;
}

/// An API whose response is held open until the test releases it, so a
/// submission can be in flight while the draft changes.
class DeferredApi {
  final seen = <SeenRequest>[];
  final gate = Completer<http.Response>();

  ReportApi build() => ReportApi(
        baseUrl: 'https://api.example.test/',
        client: MockClient((request) async {
          seen.add(SeenRequest(
            jsonDecode(request.body) as Map<String, Object?>,
            request.headers['Idempotency-Key'],
          ));
          return gate.future;
        }),
      );

  void completeAccepted([String code = 'SS-ABCD-2345']) {
    gate.complete(http.Response(jsonEncode({'code': code}), 201));
  }

  void completeFailure() {
    gate.complete(http.Response('server error', 500));
  }

  void completeSocketFailure() {
    gate.completeError(const SocketException('connection reset'));
  }

  void completeTimeout() {
    gate.completeError(TimeoutException('timed out'));
  }
}

ReportDraft filledDraft() => ReportDraft()
  ..timing = Timing.now
  ..incident = IncidentType.threats
  ..support = SupportOption.private
  ..route = 'Thika Road'
  ..area = 'Githurai 45'
  ..vehicle = 'KDA 123A'
  ..sacco = 'Super Metro';

void main() {
  final savedAt = DateTime.fromMillisecondsSinceEpoch(1760000000000);

  group('a stale submission response', () {
    test('a late success does not clear a newer edited draft', () async {
      final api = DeferredApi();
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      // A is submitted and stays in flight.
      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      expect(api.seen, hasLength(1));

      // The user edits the draft to B while A is in flight.
      controller.draft.route = 'Jogoo Road';

      // A succeeds late.
      api.completeAccepted('SS-AAAA-1111');
      await inFlight;

      // B survives untouched.
      expect(controller.draft.route, 'Jogoo Road');
      expect(controller.draft.incident, IncidentType.threats);
      expect(controller.state, isA<SucceededButDraftChanged>());
      expect((controller.state as SucceededButDraftChanged).code, 'SS-AAAA-1111');
      // The result is not the ordinary success, so nothing navigates to a
      // confirmation screen for the newer draft.
      expect(controller.state, isNot(isA<Succeeded>()));
    });

    test('a late success does not clear a newer saved draft or its record', () async {
      final api = DeferredApi();
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      final keyForA = api.seen.single.key;

      // The user edits to B and saves it while A is in flight.
      controller.draft.route = 'Jogoo Road';
      await controller.savePending();
      final keyForB = controller.currentKey;
      expect(keyForB, isNot(keyForA));

      api.completeAccepted('SS-AAAA-2222');
      await inFlight;

      // B's key and B's saved record are intact.
      expect(controller.currentKey, keyForB);
      final stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.key, keyForB);
      expect(jsonDecode(stored.canonicalPayload)['route'], 'Jogoo Road');
      expect(controller.draft.route, 'Jogoo Road');
      expect(controller.state, isA<SucceededButDraftChanged>());
      expect((controller.state as SucceededButDraftChanged).code, 'SS-AAAA-2222');
    });

    test('a late failure does not clear a newer edited draft', () async {
      final api = DeferredApi();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      final keyForA = api.seen.single.key;

      controller.draft.route = 'Jogoo Road';

      api.completeSocketFailure();
      await inFlight;

      // The failure is reported as a failure, and the newer work survives.
      expect(controller.state, isA<NetworkFailed>());
      expect(controller.draft.route, 'Jogoo Road');
      expect(controller.currentKey, keyForA);
    });

    test('a late timeout does not clear a newer saved draft or its record', () async {
      final api = DeferredApi();
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);

      controller.draft.route = 'Jogoo Road';
      await controller.savePending();
      final keyForB = controller.currentKey;

      api.completeTimeout();
      await inFlight;

      expect(controller.state, isA<NetworkFailed>().having((s) => s.timedOut, 'timedOut', isTrue));
      expect(controller.draft.route, 'Jogoo Road');
      expect(controller.currentKey, keyForB);
      expect((await store.read())!.key, keyForB);
    });

    test('an unchanged draft keeps the ordinary success behaviour', () async {
      final api = DeferredApi();
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: store,
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);

      api.completeAccepted('SS-ABCD-2345');
      await inFlight;

      // The ordinary path: the draft is cleared, the key is dropped, and the
      // state is the ordinary success.
      expect(controller.state, isA<Succeeded>().having((s) => s.code, 'code', 'SS-ABCD-2345'));
      expect(controller.draft.incident, isNull);
      expect(controller.draft.route, isEmpty);
      expect(controller.currentKey, isNull);
    });

    test('the earlier confirmation code stays available without clearing B', () async {
      final api = DeferredApi();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      controller.draft.route = 'Jogoo Road';

      api.completeAccepted('SS-AAAA-3333');
      await inFlight;

      // The code of the report that was filed is kept, and B is still there.
      final state = controller.state;
      expect(state, isA<SucceededButDraftChanged>());
      expect((state as SucceededButDraftChanged).code, 'SS-AAAA-3333');
      expect(controller.draft.route, 'Jogoo Road');
    });

    test('a key conflict does not take a newer draft key', () async {
      final api = DeferredApi();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      controller.draft.route = 'Jogoo Road';

      api.gate.complete(http.Response('conflict', 409));
      await inFlight;

      expect(controller.state, isA<UnexpectedResponse>());
      expect(controller.draft.route, 'Jogoo Road');
      expect(controller.currentKey, isNotNull);
    });

    test('the stale state survives opening the review screen again', () async {
      final api = DeferredApi();
      final controller = SubmissionController(
        api: api.build(),
        draft: filledDraft(),
        pendingStore: InMemoryPendingDraftStore(),
        clock: () => savedAt,
      );

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      controller.draft.route = 'Jogoo Road';

      api.completeAccepted('SS-AAAA-4444');
      await inFlight;

      // The review screen calls acknowledgeFailure() when it opens; the code of
      // the earlier report must not be dropped with it.
      controller.acknowledgeFailure();

      expect(controller.state, isA<SucceededButDraftChanged>());
      expect((controller.state as SucceededButDraftChanged).code, 'SS-AAAA-4444');
    });
  });
}
