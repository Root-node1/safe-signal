import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/l10n/l10n.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/screens/confirmation_screen.dart';
import 'package:safesignal/storage/in_memory_pending_draft_store.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/widgets.dart';

import 'helpers.dart';

ReportDraft _filledDraft() => ReportDraft()
  ..timing = Timing.now
  ..incident = IncidentType.threats
  ..support = SupportOption.private
  ..route = 'Thika Road'
  ..area = 'Githurai 45'
  ..vehicle = 'KDA 123A'
  ..sacco = 'Super Metro';

/// An API that records every request it sees.
class _SeenRequest {
  _SeenRequest(this.body, this.key);
  final Map<String, Object?> body;
  final String? key;
}

ReportApi _recordingApi(
  List<_SeenRequest> seen, {
  int status = 201,
  List<int>? statuses,
  String code = 'SS-ABCD-2345',
}) =>
    ReportApi(
      baseUrl: 'https://api.example.test/',
      client: MockClient((request) async {
        seen.add(_SeenRequest(
          jsonDecode(request.body) as Map<String, Object?>,
          request.headers['Idempotency-Key'],
        ));
        final index = statuses == null ? 0 : (seen.length - 1).clamp(0, statuses.length - 1);
        final statusCode = statuses == null ? status : statuses[index];
        return http.Response(jsonEncode({'code': code}), statusCode);
      }),
    );

/// A [PendingDraftStore] whose [delete] always throws [PendingDraftDeleteFailed].
class _DeleteFailingStore implements PendingDraftStore {
  _DeleteFailingStore([PendingDraft? record]) : _record = record;

  PendingDraft? _record;
  int deleteCount = 0;

  @override
  Future<PendingDraft?> read() async {
    final draft = _record;
    if (draft == null) return null;
    if (!draft.verifyChecksum()) {
      throw const PendingDraftCorrupt('checksum does not match');
    }
    return draft;
  }

  @override
  Future<void> delete() async {
    deleteCount++;
    throw const PendingDraftDeleteFailed('delete failed');
  }

  @override
  Future<void> write(PendingDraft draft) async {
    _record = draft;
  }

  @override
  Future<bool> isAvailable() async => true;
}

/// A store that fails deletes until [allowDeletes] is set to true.
class _FlipDeleteStore implements PendingDraftStore {
  _FlipDeleteStore();

  PendingDraft? _record;
  int deleteCount = 0;
  bool allowDeletes = false;

  @override
  Future<PendingDraft?> read() async {
    final draft = _record;
    if (draft == null) return null;
    if (!draft.verifyChecksum()) {
      throw const PendingDraftCorrupt('checksum does not match');
    }
    return draft;
  }

  @override
  Future<void> delete() async {
    deleteCount++;
    if (!allowDeletes) {
      throw const PendingDraftDeleteFailed('delete failed');
    }
    _record = null;
  }

  @override
  Future<void> write(PendingDraft draft) async {
    _record = draft;
  }

  @override
  Future<bool> isAvailable() async => true;
}

final DateTime _savedAt = DateTime.fromMillisecondsSinceEpoch(1760000000000);

/// Pumps the Confirmation screen for an already-instantiated [controller].
Future<void> _pumpConfirmation(
  WidgetTester tester,
  SubmissionController controller, {
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildSafeSignalTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ConfirmationScreen(controller: controller),
    ),
  );
}

void main() {
  group('T-19 race-safe deletion guard', () {
    test('a confirmed 2xx for the current attempt deletes the record', () async {
      final seen = <_SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: _recordingApi(seen, status: 201),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();

      await controller.submit();

      expect(controller.state, isA<Succeeded>());
      expect(await store.read(), isNull, reason: 'record must be deleted');
      expect(controller.currentKey, isNull);
    });

    test('a stale 2xx for a newer record does not delete it', () async {
      final seen = <_SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final gate = Completer<http.Response>();
      final deferredApi = ReportApi(
        baseUrl: 'https://api.example.test/',
        client: MockClient((request) async {
          seen.add(_SeenRequest(
            jsonDecode(request.body) as Map<String, Object?>,
            request.headers['Idempotency-Key'],
          ));
          return gate.future;
        }),
      );

      final controller = SubmissionController(
        api: deferredApi,
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      final keyBeforeEdit = controller.currentKey;

      // Start submitting A, then edit and save B while in flight.
      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      controller.draft.route = 'Jogoo Road';
      await controller.savePending();
      final keyForB = controller.currentKey;
      expect(keyForB, isNot(keyBeforeEdit));

      // Complete A's response (stale).
      gate.complete(http.Response(jsonEncode({'code': 'SS-AAAA-1111'}), 201));
      await inFlight;

      // A's stale success must not delete B's record.
      final stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.key, keyForB);
    });

    test('a confirmed 2xx when pendingMatchesAttempt is false does not delete',
        () async {
      final seen = <_SeenRequest>[];
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: _recordingApi(seen, status: 201),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      // Edit without saving: the stored key no longer matches the attempt.
      controller.draft.route = 'Jogoo Road';
      await controller.submit();

      // The draft was edited, so the stale 2xx produces SucceededButDraftChanged
      // (not Succeeded) to preserve the newer draft and its key.
      expect(controller.state, isA<SucceededButDraftChanged>());
      // The stored record was never deleted because pendingMatchesAttempt was false.
      expect(await store.read(), isNotNull);
      expect(controller.pendingMatchesAttempt, isFalse);
    });
  });

  group('T-19 prepareForQuickExit', () {
    test('deletes the pending record and clears the draft', () async {
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      expect(controller.currentKey, isNotNull);
      expect(controller.draft.incident, isNotNull);

      final status = await controller.prepareForQuickExit();

      expect(status, QuickExitDeletionStatus.success);
      expect(await store.read(), isNull);
      expect(controller.currentKey, isNull);
      expect(controller.draft.incident, isNull);
      expect(controller.state, isA<Idle>());
    });

    test('returns recordRetained when delete fails', () async {
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      expect(store.deleteCount, 0);

      final status = await controller.prepareForQuickExit();

      expect(status, QuickExitDeletionStatus.recordRetained);
      expect(store.deleteCount, 1);
      // Even on failure, draft and key are cleared for exit.
      expect(controller.currentKey, isNull);
      expect(controller.draft.incident, isNull);
    });

    test('returns success when there is no store', () async {
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
      );

      final status = await controller.prepareForQuickExit();

      expect(status, QuickExitDeletionStatus.success);
    });

    test('invalidates an in-flight submission so a late 2xx is ignored', () async {
      final gate = Completer<http.Response>();
      final api = ReportApi(
        baseUrl: 'https://api.example.test/',
        client: MockClient((request) async => gate.future),
      );
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: api,
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();

      final inFlight = controller.submit();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, isA<Submitting>());

      final exitStatus = await controller.prepareForQuickExit();
      expect(exitStatus, QuickExitDeletionStatus.success);

      gate.complete(http.Response(jsonEncode({'code': 'SS-ABCD-2345'}), 201));
      await inFlight;

      // State stays Idle — the late response is dropped.
      expect(controller.state, isA<Idle>());
      expect(controller.currentKey, isNull);
    });
  });

  group('T-19 retryQuickExitDeletion', () {
    test('retries and succeeds', () async {
      final flipStore = _FlipDeleteStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: flipStore,
        clock: () => _savedAt,
      );
      await controller.savePending();

      // First attempt fails.
      final first = await controller.prepareForQuickExit();
      expect(first, QuickExitDeletionStatus.recordRetained);
      expect(flipStore.deleteCount, 1);

      // Flip the store to allow deletes.
      flipStore.allowDeletes = true;

      final second = await controller.retryQuickExitDeletion();
      expect(second, QuickExitDeletionStatus.success);
      expect(flipStore.deleteCount, 2);
      expect(await flipStore.read(), isNull);
    });

    test('retries and fails again', () async {
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.prepareForQuickExit();
      expect(store.deleteCount, 1);

      final status = await controller.retryQuickExitDeletion();

      expect(status, QuickExitDeletionStatus.recordRetained);
      expect(store.deleteCount, 2);
    });

    test('returns success when there is no store', () async {
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
      );

      final status = await controller.retryQuickExitDeletion();

      expect(status, QuickExitDeletionStatus.success);
    });
  });

  group('T-19 retryPendingDeletion', () {
    test('succeeds and transitions to Succeeded', () async {
      final flipStore = _FlipDeleteStore();
      final controller = SubmissionController(
        api: _recordingApi([], status: 201),
        draft: _filledDraft(),
        pendingStore: flipStore,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.submit();

      expect(controller.state, isA<SucceededButRecordRetained>());
      expect(flipStore.deleteCount, 1);

      flipStore.allowDeletes = true;
      final ok = await controller.retryPendingDeletion();

      expect(ok, isTrue);
      expect(controller.state, isA<Succeeded>());
      expect((controller.state as Succeeded).code, 'SS-ABCD-2345');
      expect(await flipStore.read(), isNull);
      expect(controller.currentKey, isNull);
      expect(controller.draft.incident, isNull);
    });

    test('fails and stays in SucceededButRecordRetained without retrying HTTP',
        () async {
      final seen = <_SeenRequest>[];
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi(seen, status: 201),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.submit();

      expect(controller.state, isA<SucceededButRecordRetained>());
      expect(seen, hasLength(1));

      final result = await controller.retryPendingDeletion();

      expect(result, isFalse);
      expect(seen, hasLength(1), reason: 'no HTTP retry');
      expect(controller.state, isA<SucceededButRecordRetained>());
    });

    test('returns true when there is no store', () async {
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        clock: () => _savedAt,
      );

      final result = await controller.retryPendingDeletion();

      expect(result, isTrue);
    });
  });

  group('T-19 SucceededButRecordRetained state', () {
    test('is distinct from Succeeded and carries the delete error', () async {
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([], status: 201),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.submit();

      expect(controller.state, isA<SucceededButRecordRetained>());
      expect(controller.state, isNot(isA<Succeeded>()));
      expect(
        (controller.state as SucceededButRecordRetained).code,
        'SS-ABCD-2345',
      );
      expect(
        (controller.state as SucceededButRecordRetained).deleteError,
        isA<PendingDraftDeleteFailed>(),
      );
    });

    test('preserves draft, key and record', () async {
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([], status: 201),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      final savedKey = controller.currentKey;

      await controller.submit();

      expect(controller.state, isA<SucceededButRecordRetained>());
      expect(controller.currentKey, savedKey);
      expect(controller.draft.incident, isNotNull);
      expect(await store.read(), isNotNull);
    });
  });

  group('T-19 confirmation screen: SucceededButRecordRetained', () {
    /// Builds a controller that submitted with a failing delete, leaving it in
    /// SucceededButRecordRetained.
    Future<SubmissionController> retainedController() async {
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([], status: 201),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.submit();
      expect(controller.state, isA<SucceededButRecordRetained>());
      return controller;
    }

    testWidgets('shows the reference code alongside the record-retained banner',
        (tester) async {
      tallPhone(tester);
      final controller = await retainedController();

      await _pumpConfirmation(tester, controller);

      // The reference code is shown — the report was accepted.
      expect(find.text('Report received'), findsOneWidget);
      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(find.text('Reference code'), findsOneWidget);

      // The record-retained banner is shown.
      expect(find.text('Your report is still saved'), findsOneWidget);
      expect(
        find.text(
          'The report was accepted by the server, but SafeSignal could not '
          'delete the saved copy on this phone. No duplicate will be sent, '
          'but the report remains on this device until it is deleted.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows a Delete saved report button that recovers the state',
        (tester) async {
      tallPhone(tester);
      final flipStore = _FlipDeleteStore();
      final controller = SubmissionController(
        api: _recordingApi([], status: 201),
        draft: _filledDraft(),
        pendingStore: flipStore,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.submit();
      expect(controller.state, isA<SucceededButRecordRetained>());

      await _pumpConfirmation(tester, controller);

      expect(find.text('Delete saved report'), findsOneWidget);

      // Make the store succeed on retry.
      flipStore.allowDeletes = true;

      final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete saved report');
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // After retry, state transitions to Succeeded.
      expect(controller.state, isA<Succeeded>());
      expect(find.text('Your report is still saved'), findsNothing);
    });

    testWidgets('Delete saved report failure shows a snackbar', (tester) async {
      tallPhone(tester);
      final controller = await retainedController();

      await _pumpConfirmation(tester, controller);

      await tapButton(tester, 'Delete saved report');
      await tester.pumpAndSettle();

      expect(find.text('The report is still saved on this phone.'), findsOneWidget);
      expect(controller.state, isA<SucceededButRecordRetained>());
    });

    testWidgets('the record-retained banner is a live region', (tester) async {
      tallPhone(tester);
      final controller = await retainedController();

      await _pumpConfirmation(tester, controller);

      expect(hasLiveRegionNode(tester), isTrue);
    });

    testWidgets('shows helplines alongside the record-retained banner',
        (tester) async {
      tallPhone(tester);
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([], status: 201),
        draft: _filledDraft()..support = SupportOption.support,
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      await controller.submit();

      await _pumpConfirmation(tester, controller);

      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(find.text('Delete saved report'), findsOneWidget);
      expect(find.text('Emergency and support numbers'), findsOneWidget);
    });

    testWidgets('renders in Kiswahili', (tester) async {
      tallPhone(tester);
      final controller = await retainedController();

      await _pumpConfirmation(tester, controller, locale: const Locale('sw'));

      expect(find.text('Ripoti imepokelewa'), findsOneWidget);
      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(find.text('Futa ripoti iliyopotekwa'), findsOneWidget);
    });
  });

  group('T-19 Quick Exit button failure dialog', () {
    /// Pumps the QuickExitButton on a plain Scaffold.
    Future<void> pumpButton(
      WidgetTester tester,
      SubmissionController controller,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSafeSignalTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: QuickExitButton(controller: controller))),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows Try again / Exit anyway when deletion fails',
        (tester) async {
      tallPhone(tester);
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();

      await pumpButton(tester, controller);

      await tester.tap(find.byType(QuickExitButton));
      // Allow the async quickExit flow to run to completion.
      await tester.pump(); // start
      await tester.pump(); // microtasks: prepareForQuickExit completes
      await tester.pumpAndSettle(); // dialog renders

      expect(find.text('Your report is still saved'), findsOneWidget);
      expect(
        find.text(
          'SafeSignal could not delete the saved report on this phone before '
          'exiting. The app will still close, but the report remains on this device.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Exit anyway'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    });

    testWidgets('Try again retries and exits on success', (tester) async {
      tallPhone(tester);
      final flipStore = _FlipDeleteStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: flipStore,
        clock: () => _savedAt,
      );
      await controller.savePending();

      await pumpButton(tester, controller);

      await tester.tap(find.byType(QuickExitButton));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(flipStore.deleteCount, 1);
      expect(find.text('Your report is still saved'), findsOneWidget);

      flipStore.allowDeletes = true;
      await tapButton(tester, 'Try again');
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Your report is still saved'), findsNothing);
      expect(flipStore.deleteCount, 2);
    });

    testWidgets('Exit anyway closes without extra deletion attempts',
        (tester) async {
      tallPhone(tester);
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();

      await pumpButton(tester, controller);

      await tester.tap(find.byType(QuickExitButton));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(store.deleteCount, 1);

      await tapButton(tester, 'Exit anyway');
      await tester.pumpAndSettle();

      expect(store.deleteCount, 1);
      expect(find.text('Your report is still saved'), findsNothing);
    });

    testWidgets('double-tapping Exit does not spawn duplicate dialogs',
        (tester) async {
      tallPhone(tester);
      final store = _DeleteFailingStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();

      await pumpButton(tester, controller);

      // Tap the button — the first tap starts quickExit.
      await tester.tap(find.byType(QuickExitButton));
      await tester.pump();
      // The widget is now disabled (inProgress), so a second tap is a no-op.
      await tester.tap(find.byType(QuickExitButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Your report is still saved'), findsOneWidget);
      expect(store.deleteCount, 1, reason: 'only one deletion attempt');
    });

    testWidgets('Exit succeeds and closes when deletion works', (tester) async {
      tallPhone(tester);
      final store = InMemoryPendingDraftStore();
      final controller = SubmissionController(
        api: _recordingApi([]),
        draft: _filledDraft(),
        pendingStore: store,
        clock: () => _savedAt,
      );
      await controller.savePending();
      expect(await store.read(), isNotNull);

      await pumpButton(tester, controller);

      await tester.tap(find.byType(QuickExitButton));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // No failure dialog.
      expect(find.text('Your report is still saved'), findsNothing);
      // Record was deleted.
      expect(await store.read(), isNull);
    });
  });
}


