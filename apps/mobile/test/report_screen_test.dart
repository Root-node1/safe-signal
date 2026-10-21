// Tests for the Flutter Incident Type screen (lib/screens/report_screen.dart).
//
// Covers the M.3 redesign of this step: the StepHeader progress label, the
// SafeSignalTile radio group, the danger-note banner, the token spacing, the
// Kiswahili strings, and the TalkBack semantics that must survive the swap.

import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/l10n/l10n.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/screens/report_screen.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/widgets.dart';

import 'helpers.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Pumps the Incident Type screen on its own, with a draft we can inspect.
Future<SubmissionController> pumpReport(
  WidgetTester tester, {
  Locale? locale,
  ThemeMode mode = ThemeMode.light,
}) async {
  final controller = SubmissionController(api: ReportApi(baseUrl: ''));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildSafeSignalTheme(),
      darkTheme: buildSafeSignalDarkTheme(),
      themeMode: mode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReportScreen(controller: controller),
    ),
  );
  return controller;
}

/// The semantics node of the incident tile whose label starts with [title].
SemanticsNode _tileNode(WidgetTester tester, String title) {
  final nodes = tester.semantics.simulatedAccessibilityTraversal();
  return nodes.firstWhere(
    (n) => n.flagsCollection.isInMutuallyExclusiveGroup &&
        n.label.startsWith(title),
    orElse: () => throw TestFailure('No incident tile found for "$title"'),
  );
}

/// How many incident tiles currently report themselves as selected.
int _selectedTileCount(WidgetTester tester) => tester
    .semantics
    .simulatedAccessibilityTraversal()
    .where((n) =>
        n.flagsCollection.isInMutuallyExclusiveGroup &&
        n.flagsCollection.isChecked == CheckedState.isTrue)
    .length;

void main() {
  group('Incident Type screen', () {
    testWidgets('shows the step header, six incident tiles, and the details '
        'section', (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      expect(find.byType(StepHeader), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('What happened?'), findsOneWidget);
      expect(find.byType(SafeSignalTile), findsNWidgets(6));
      expect(find.text('Details (optional)'), findsOneWidget);
    });

    testWidgets('the heading is announced as a heading', (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      final headers = tester
          .semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.flagsCollection.isHeader)
          .toList();
      expect(
        headers.any((n) => n.label.contains('What happened?')),
        isTrue,
        reason: 'the step heading must be announced as a heading',
      );
    });

    testWidgets('tapping a tile selects it and records it in the draft',
        (tester) async {
      tallPhone(tester);
      final controller = await pumpReport(tester);

      await tester.tap(find.text('Unwanted touching'));
      await tester.pumpAndSettle();

      expect(controller.draft.incident, IncidentType.touching);
      expect(
        _tileNode(tester, 'Unwanted touching').flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      expect(_selectedTileCount(tester), 1);
    });

    testWidgets('choosing another tile moves the selection', (tester) async {
      tallPhone(tester);
      final controller = await pumpReport(tester);

      await tester.tap(find.text('Unwanted touching'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Someone is threatening me'));
      await tester.pumpAndSettle();

      expect(controller.draft.incident, IncidentType.threats);
      expect(
        _tileNode(tester, 'Unwanted touching').flagsCollection.isChecked,
        isNot(CheckedState.isTrue),
      );
      expect(
        _tileNode(tester, 'Someone is threatening me').flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      expect(_selectedTileCount(tester), 1);
    });

    testWidgets('Continue without a choice shows the error and stays put',
        (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      await tapButton(tester, 'Continue');

      expect(find.text('Choose what happened to continue.'), findsOneWidget);
      expect(find.text('What would help most?'), findsNothing);
    });

    testWidgets('the choice error is announced as a live region',
        (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      expect(hasLiveRegionNode(tester), isFalse);

      await tapButton(tester, 'Continue');

      expect(hasLiveRegionNode(tester), isTrue);
    });

    testWidgets('Continue with a choice opens the support step',
        (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      await tester.tap(find.text('Unwanted touching'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Continue');

      expect(find.text('What would help most?'), findsOneWidget);
    });

    testWidgets('the danger notice appears only when it is happening now',
        (tester) async {
      tallPhone(tester);
      final controller = await pumpReport(tester);

      expect(find.textContaining('call 999 or 112'), findsNothing);

      await tester.tap(find.text('Happening now'));
      await tester.pumpAndSettle();

      expect(controller.draft.timing, Timing.now);
      expect(find.byType(SafeSignalBanner), findsOneWidget);
      expect(find.textContaining('call 999 or 112'), findsOneWidget);
    });

    testWidgets('each tile is announced as a radio item with its description',
        (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      final node = _tileNode(tester, 'Unwanted touching');
      expect(
        node.label,
        'Unwanted touching. Non-consensual physical contact, crowding, or '
        'invasion of space.',
      );
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(node.flagsCollection.isButton, isTrue);
    });

    testWidgets('tiles meet the minimum touch target', (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(SafeSignalTile).first,
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(
        container.constraints?.minHeight ?? 0.0,
        greaterThanOrEqualTo(kTouchMin),
      );
    });

    testWidgets('the primary and secondary actions share one height',
        (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      final continueHeight = tester
          .getSize(find.widgetWithText(FilledButton, 'Continue'))
          .height;
      final backHeight = tester
          .getSize(find.widgetWithText(OutlinedButton, 'Back'))
          .height;

      expect(continueHeight, greaterThanOrEqualTo(kTouchMin));
      expect(backHeight, greaterThanOrEqualTo(kTouchMin));
      expect(backHeight, closeTo(continueHeight, 0.01));
    });

    testWidgets('Quick Exit stays available on this step', (tester) async {
      tallPhone(tester);
      await pumpReport(tester);

      expect(find.byType(QuickExitButton), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('shows the step header, tiles, and details in Kiswahili',
        (tester) async {
      tallPhone(tester);
      await pumpReport(tester, locale: const Locale('sw'));

      expect(find.text('Hatua ya 1 kati ya 3'), findsOneWidget);
      expect(find.text('Nini kilitokea?'), findsOneWidget);
      expect(find.text('Kuguswa bila ridhaa yangu'), findsOneWidget);
      expect(
        find.text(
          'Kuguswa mwilini bila ridhaa, kusongamana, au kuvamiwa nafasi yako.',
        ),
        findsOneWidget,
      );
      expect(find.text('Maelezo (hiari)'), findsOneWidget);
    });

    testWidgets('respects reduced motion and still records the choice',
        (tester) async {
      tallPhone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final controller = await pumpReport(tester);

      await tester.tap(find.text('Unwanted touching'));
      await tester.pumpAndSettle();

      expect(controller.draft.incident, IncidentType.touching);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      tallPhone(tester);
      await pumpReport(tester, mode: ThemeMode.dark);

      expect(find.text('What happened?'), findsOneWidget);
      expect(find.byType(SafeSignalTile), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kiswahili tiles fit at 2x text scale on a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpReport(tester, locale: const Locale('sw'));
      await reveal(tester, find.text('Kuguswa bila ridhaa yangu'));

      expect(find.text('Kuguswa bila ridhaa yangu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens from the welcome screen with the step header',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      await tapButton(tester, 'Report an incident');

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('What happened?'), findsOneWidget);
    });
  });
}
