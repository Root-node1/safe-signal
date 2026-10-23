// Tests for the Flutter Review screen (lib/screens/review_screen.dart).
//
// Covers the M.3 redesign of this step: the StepHeader, the token-based
// summary surface, the error banner, and the truthfulness of the submission
// states.  Submission logic itself is owned by SubmissionController and is
// covered by report_api_test.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/l10n/l10n.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/screens/review_screen.dart';
import 'package:safesignal/storage/in_memory_pending_draft_store.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/widgets.dart';

import 'helpers.dart';

/// A valid, unexpired draft record for discard tests.
final PendingDraft kPendingRecord = PendingDraft(
  payload: {
    'incident': 'harassment',
    'timing': 'now',
    'route': 'Test Route',
    'area': 'Test Area',
    'vehicle': 'KDA 123A',
    'sacco': 'Test SACCO',
    'support': 'private',
    'contactProvided': false,
    'consentToShare': false,
  },
  key: 'review-test-key',
  createdAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
  expiresAt: DateTime.utc(2026, 1, 1)
      .add(const Duration(hours: 25))
      .millisecondsSinceEpoch,
);

/// Pumps the Review screen with the given [draft] and returns its controller.
Future<SubmissionController> pumpReview(
  WidgetTester tester, {
  ReportDraft? draft,
  ReportApi? api,
  Locale? locale,
  ThemeMode mode = ThemeMode.light,
  PendingDraftStore? pendingStore,
  DateTime Function()? clock,
}) async {
  final controller = SubmissionController(
    api: api ?? okApi(),
    draft: draft ?? ReportDraft(),
    pendingStore: pendingStore,
    clock: clock,
  );
  // Populate pendingOutcome from the store so the Discard button is visible.
  if (pendingStore != null) {
    await controller.readPendingReport();
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: buildSafeSignalTheme(),
      darkTheme: buildSafeSignalDarkTheme(),
      themeMode: mode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReviewScreen(controller: controller),
    ),
  );
  return controller;
}

/// A draft with every field filled in.
ReportDraft fullDraft() => ReportDraft()
  ..timing = Timing.after
  ..incident = IncidentType.touching
  ..route = 'Thika Road'
  ..vehicle = 'kda 123a'
  ..sacco = 'Super Metro'
  ..area = 'Near Githurai 45'
  ..support = SupportOption.support;

void main() {
  group('Review screen', () {
    testWidgets('shows the step header and every report field', (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());

      expect(find.byType(StepHeader), findsOneWidget);
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Review your details'), findsOneWidget);
      expect(
        find.text(
          'Nothing has been sent yet. Tap Submit report to send this to '
          'SafeSignal. SafeSignal is not an emergency service.',
        ),
        findsOneWidget,
      );

      // Row keys.
      expect(find.text('When'), findsOneWidget);
      expect(find.text('What happened'), findsOneWidget);
      expect(find.text('Route or corridor'), findsOneWidget);
      expect(find.text('Number plate or matatu name'), findsOneWidget);
      expect(find.text('SACCO or operator'), findsOneWidget);
      expect(find.text('Where did it happen?'), findsOneWidget);
      expect(find.text('What would help most'), findsOneWidget);

      // Row values.
      expect(find.text('Already happened'), findsOneWidget);
      expect(find.text('Unwanted touching'), findsOneWidget);
      expect(find.text('Thika Road'), findsOneWidget);
      expect(find.text('KDA 123A'), findsOneWidget);
      expect(find.text('Super Metro'), findsOneWidget);
      expect(find.text('Near Githurai 45'), findsOneWidget);
      expect(find.text('Show emergency and support phone numbers'), findsOneWidget);
    });

    testWidgets('blank optional fields are labelled, not hidden',
        (tester) async {
      tallPhone(tester);
      await pumpReview(
        tester,
        draft: ReportDraft()
          ..incident = IncidentType.unsure
          ..support = SupportOption.private,
      );

      expect(find.text('Not provided'), findsNWidgets(4));
    });

    testWidgets('the timing row follows the chosen timing', (tester) async {
      tallPhone(tester);
      await pumpReview(
        tester,
        draft: ReportDraft()
          ..timing = Timing.now
          ..incident = IncidentType.harassment
          ..support = SupportOption.private,
      );

      expect(find.text('Happening now'), findsOneWidget);
      expect(find.text('Already happened'), findsNothing);
    });

    testWidgets('the heading is announced as a heading', (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());

      final headers = tester
          .semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.flagsCollection.isHeader)
          .toList();
      expect(
        headers.any((n) => n.label.contains('Review your details')),
        isTrue,
        reason: 'the step heading must be announced as a heading',
      );
    });

    testWidgets('the summary rows are grouped for screen readers',
        (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());

      final groups = tester
          .semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.label.contains('Thika Road'))
          .toList();
      expect(groups, isNotEmpty);
      expect(
        groups.first.label,
        contains('Route or corridor'),
        reason: 'a summary row is read as one group: key and value together',
      );
      expect(
        groups.first.flagsCollection.isHeader,
        isFalse,
        reason: 'a summary row is a group, not a heading',
      );
    });

    testWidgets('both actions meet the minimum touch target', (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());

      final submitHeight =
          tester.getSize(find.widgetWithText(FilledButton, 'Submit report')).height;
      final editHeight =
          tester.getSize(find.widgetWithText(OutlinedButton, 'Edit details')).height;

      expect(submitHeight, greaterThanOrEqualTo(kTouchMin));
      expect(editHeight, greaterThanOrEqualTo(kTouchMin));
      expect(editHeight, closeTo(submitHeight, 0.01));
    });

    testWidgets('Quick Exit stays available on this step', (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());

      expect(find.byType(QuickExitButton), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('shows the step header and rows in Kiswahili', (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft(), locale: const Locale('sw'));

      expect(find.text('Hatua ya 3 kati ya 3'), findsOneWidget);
      expect(find.text('Kagua maelezo yako'), findsOneWidget);
      expect(find.text('Lini'), findsOneWidget);
      expect(find.text('Kilichotokea'), findsOneWidget);
      expect(find.text('Kinachosaidia zaidi'), findsOneWidget);
      expect(find.text('Thika Road'), findsOneWidget);
      expect(find.text('Tuma ripoti'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft(), mode: ThemeMode.dark);

      expect(find.text('Review your details'), findsOneWidget);
      expect(find.text('Thika Road'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kiswahili summary fits at 2x text scale on a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpReview(tester, draft: fullDraft(), locale: const Locale('sw'));
      await reveal(tester, find.text('Thika Road'));

      expect(find.text('Thika Road'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a validation failure is shown as a live-region banner',
        (tester) async {
      tallPhone(tester);
      await pumpReview(tester);

      expect(hasLiveRegionNode(tester), isFalse);

      await tapButton(tester, 'Submit report');
      await tester.pumpAndSettle();

      expect(find.byType(SafeSignalBanner), findsOneWidget);
      expect(
        find.text(
          'The server could not accept some details. Tap Edit details to check '
          'them, then try again.',
        ),
        findsOneWidget,
      );
      expect(hasLiveRegionNode(tester), isTrue);
      // The report is still on screen so the details can be corrected.
      expect(find.text('Review your details'), findsOneWidget);
    });

    testWidgets('a network failure keeps the details for a retry',
        (tester) async {
      tallPhone(tester);
      final api = ReportApi(
        baseUrl: 'http://test.invalid',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await pumpReview(tester, draft: fullDraft(), api: api);

      await tapButton(tester, 'Submit report');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Could not reach SafeSignal. Check your connection and tap Submit '
          'report to try again. Your details are still here.',
        ),
        findsOneWidget,
      );
      expect(find.text('Thika Road'), findsOneWidget);
      expect(find.text('Review your details'), findsOneWidget);
    });

    testWidgets('while submitting it shows progress and blocks a second tap',
        (tester) async {
      tallPhone(tester);
      final completer = Completer<http.Response>();
      final api = ReportApi(
        baseUrl: 'http://test.invalid',
        client: MockClient((_) => completer.future),
      );
      await pumpReview(tester, draft: fullDraft(), api: api);

      await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
      await tester.pump();

      expect(find.text('Submitting…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(hasLiveRegionNode(tester), isTrue);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submitting…'),
      );
      expect(button.onPressed, isNull, reason: 'no double submit while in flight');

      completer.complete(http.Response('{"code":"SS-ABCD-2345"}', 201));
      await tester.pumpAndSettle();

      expect(find.text('Report received'), findsOneWidget);
    });

    testWidgets('a successful report opens the confirmation step',
        (tester) async {
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());

      await tapButton(tester, 'Submit report');
      await tester.pumpAndSettle();

      expect(find.text('Report received'), findsOneWidget);
      expect(find.text('SS-ABCD-2345'), findsOneWidget);
    });

    testWidgets('Edit details returns to the support step with the choice kept',
        (tester) async {
      phone(tester);
      await openReport(tester);
      await tapText(tester, 'Unwanted touching');
      await tapButton(tester, 'Continue');
      await tapText(tester, 'Submit without contacting anyone');
      await tapButton(tester, 'Review');

      expect(find.text('Review your details'), findsOneWidget);

      await tapButton(tester, 'Edit details');
      await toTop(tester);

      expect(find.text('What would help most?'), findsOneWidget);
      await reveal(tester, find.text('Submit without contacting anyone'));
      expect(find.text('Submit without contacting anyone'), findsOneWidget);

       // The choice is still in the draft: reviewing again shows it.
      await tapButton(tester, 'Review');
      expect(find.text('Submit without contacting anyone'), findsOneWidget);
    });
  });

  // ─── T-17 Discard from review screen ────────────────────────────────────────

  group('T-17 discard from review screen', () {
    testWidgets('Discard button visible only when a pending report exists',
        (tester) async {
      // No pending store: no discard button.
      tallPhone(tester);
      await pumpReview(tester, draft: fullDraft());
      expect(find.text('Discard saved report'), findsNothing);

      // With a valid pending report: discard button is visible.
      final store = InMemoryPendingDraftStore();
      await store.write(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report'), findsOneWidget);
    });

    testWidgets('Discard button is visually subordinate to Submit',
        (tester) async {
      tallPhone(tester);
      final store = InMemoryPendingDraftStore();
      await store.write(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      // The discard action is a TextButton (subordinate), not a FilledButton.
      expect(find.widgetWithText(TextButton, 'Discard saved report'),
          findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Submit report'),
          findsOneWidget);
    });

    testWidgets('confirming discard removes the record and pops to first route',
        (tester) async {
      tallPhone(tester);
      final store = InMemoryPendingDraftStore();
      await store.write(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report'), findsOneWidget);

      await tapButton(tester, 'Discard saved report');
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Discard saved report?'), findsOneWidget);
      expect(
        find.text('This deletes the report saved on this phone. It cannot be undone.'),
        findsOneWidget,
      );

      // Confirm
      await tapButton(tester, 'Discard');
      await tester.pumpAndSettle();

      // Record is gone.
      expect(await store.read(), isNull);
    });

    testWidgets('cancel in confirmation preserves the report', (tester) async {
      tallPhone(tester);
      final store = InMemoryPendingDraftStore();
      await store.write(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      await tapButton(tester, 'Discard saved report');
      await tester.pumpAndSettle();

      await tapButton(tester, 'Cancel');
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsNothing);
      expect(await store.read(), isNotNull);
      // Still on the review screen.
      expect(find.text('Review your details'), findsOneWidget);
    });

    testWidgets('failed discard shows an error banner and retains the record',
        (tester) async {
      tallPhone(tester);

      // Store whose delete always fails.
      final store = _ReviewDeleteFailedStore(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      await tapButton(tester, 'Discard saved report');
      await tester.pumpAndSettle();

      await tapButton(tester, 'Discard');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(
        find.text('Could not delete the saved report.'),
        findsOneWidget,
      );
      expect(
        find.text('The report is still saved on this phone.'),
        findsOneWidget,
      );
      expect(await store.read(), isNotNull);
    });

    testWidgets('discard error banner is a live region', (tester) async {
      tallPhone(tester);
      final store = _ReviewDeleteFailedStore(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      await tapButton(tester, 'Discard saved report');
      await tester.pumpAndSettle();
      await tapButton(tester, 'Discard');
      await tester.pumpAndSettle();

      expect(hasLiveRegionNode(tester), isTrue,
          reason: 'discard-failure banner must be a live region (AR-4.1)');
    });

    testWidgets('confirmation and error text localised in Kiswahili',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('sw', 'KE')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
        locale: const Locale('sw'),
      );
      await tester.pumpAndSettle();

      await tapButton(tester, 'Futa ripoti iliyopotekwa');
      await tester.pumpAndSettle();

      expect(find.text('Futa ripoti iliyopotekwa?'), findsOneWidget);

      await tapButton(tester, 'Futa');
      await tester.pumpAndSettle();

      expect(await store.read(), isNull);
    });

    testWidgets('renders without overflow at 2x text scale', (tester) async {
      phone(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kPendingRecord);
      await pumpReview(
        tester,
        draft: fullDraft(),
        pendingStore: store,
        clock: () => DateTime.utc(2026, 1, 1, 12),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Store used by review-screen discard tests: [delete] always throws
/// [PendingDraftDeleteFailed] so the error banner path can be exercised.
class _ReviewDeleteFailedStore implements PendingDraftStore {
  _ReviewDeleteFailedStore(this.record);

  PendingDraft? record;
  int deleteCount = 0;

  @override
  Future<PendingDraft?> read() async => record;

  @override
  Future<void> delete() async {
    deleteCount++;
    throw const PendingDraftDeleteFailed('delete failed');
  }

  @override
  Future<void> write(PendingDraft draft) async {
    record = draft;
  }

  @override
  Future<bool> isAvailable() async => true;
}
