// Tests for the Flutter support / next-step screen
// (lib/screens/support_screen.dart).
//
// Covers the M.3 redesign of this step: the StepHeader progress label, the
// SafeSignalTile radio group with dimmed "unavailable" options, the error
// banner, token spacing, the Kiswahili strings, and the TalkBack semantics
// that must survive the swap.

import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/l10n/l10n.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/screens/report_screen.dart';
import 'package:safesignal/screens/support_screen.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/widgets.dart';

import 'helpers.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Pumps the support step on its own, with a draft we can inspect.
Future<SubmissionController> pumpSupport(
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
      home: SupportScreen(controller: controller),
    ),
  );
  return controller;
}

/// The semantics node of the support tile whose label starts with [title].
SemanticsNode _tileNode(WidgetTester tester, String title) {
  final nodes = tester.semantics.simulatedAccessibilityTraversal();
  return nodes.firstWhere(
    (n) => n.flagsCollection.isInMutuallyExclusiveGroup &&
        n.label.startsWith(title),
    orElse: () => throw TestFailure('No support tile found for "$title"'),
  );
}

/// How many support tiles currently report themselves as selected.
int _selectedTileCount(WidgetTester tester) => tester
    .semantics
    .simulatedAccessibilityTraversal()
    .where((n) =>
        n.flagsCollection.isInMutuallyExclusiveGroup &&
        n.flagsCollection.isChecked == CheckedState.isTrue)
    .length;

void main() {
  group('Support step', () {
    testWidgets('shows the step header, the intro, and the four options',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      expect(find.byType(StepHeader), findsOneWidget);
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('What would help most?'), findsOneWidget);
      expect(
        find.text(
          'Choose an option. Nothing is sent until you submit on the last step.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SafeSignalTile), findsNWidgets(4));
    });

    testWidgets('unavailable options keep their tag and dimmed treatment',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      expect(find.text('Unavailable · In development'), findsNWidgets(2));
      expect(
        find.text('Unavailable · In development'),
        findsNWidgets(SupportOption.values.where((o) => !o.available).length),
      );
    });

    testWidgets('the heading is announced as a heading', (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      final headers = tester
          .semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.flagsCollection.isHeader)
          .toList();
      expect(
        headers.any((n) => n.label.contains('What would help most?')),
        isTrue,
        reason: 'the step heading must be announced as a heading',
      );
    });

    testWidgets('tapping an option selects it and records it in the draft',
        (tester) async {
      tallPhone(tester);
      final controller = await pumpSupport(tester);

      await tester.tap(find.text('Submit without contacting anyone'));
      await tester.pumpAndSettle();

      expect(controller.draft.support, SupportOption.private);
      expect(
        _tileNode(tester, 'Submit without contacting anyone')
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      expect(_selectedTileCount(tester), 1);
    });

    testWidgets('choosing another option moves the selection', (tester) async {
      tallPhone(tester);
      final controller = await pumpSupport(tester);

      await tester.tap(find.text('Submit without contacting anyone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show emergency and support phone numbers'));
      await tester.pumpAndSettle();

      expect(controller.draft.support, SupportOption.support);
      expect(
        _tileNode(tester, 'Submit without contacting anyone')
            .flagsCollection
            .isChecked,
        isNot(CheckedState.isTrue),
      );
      expect(
        _tileNode(tester, 'Show emergency and support phone numbers')
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      expect(_selectedTileCount(tester), 1);
    });

    testWidgets('unavailable options cannot be selected', (tester) async {
      tallPhone(tester);
      final controller = await pumpSupport(tester);

      await tester.tap(find.text('Alert someone I trust'));
      await tester.pumpAndSettle();

      expect(controller.draft.support, isNull);
      expect(_selectedTileCount(tester), 0);
      expect(
        _tileNode(tester, 'Alert someone I trust').flagsCollection.isEnabled,
        Tristate.isFalse,
        reason: 'an option that is still in development must not be enabled',
      );
    });

    testWidgets('an available option is announced with its hint',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      final node = _tileNode(tester, 'Submit without contacting anyone');
      expect(
        node.label,
        'Submit without contacting anyone. Your report goes to SafeSignal only. '
        'Nobody else is contacted.',
      );
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
    });

    testWidgets('an unavailable option announces that it is unavailable',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      final node = _tileNode(tester, 'Alert someone I trust');
      expect(
        node.label,
        'Alert someone I trust. Automated SMS to a person you choose is in '
        'development and not available. Unavailable, in development.',
      );
    });

    testWidgets('tiles meet the minimum touch target', (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

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

    testWidgets('Review without a choice shows the error and stays put',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      await tapButton(tester, 'Review');

      expect(
        find.text('Choose an available option to continue.'),
        findsOneWidget,
      );
      expect(find.byType(SafeSignalBanner), findsOneWidget);
      expect(find.text('Step 3 of 3'), findsNothing);
    });

    testWidgets('the choice error is announced as a live region',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      expect(hasLiveRegionNode(tester), isFalse);

      await tapButton(tester, 'Review');

      expect(hasLiveRegionNode(tester), isTrue);
    });

    testWidgets('choosing an option clears the error', (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      await tapButton(tester, 'Review');
      expect(find.byType(SafeSignalBanner), findsOneWidget);

      await tester.tap(find.text('Submit without contacting anyone'));
      await tester.pumpAndSettle();

      expect(find.byType(SafeSignalBanner), findsNothing);
    });

    testWidgets('Review with a choice opens the review step', (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      await tester.tap(find.text('Submit without contacting anyone'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Review');

      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Review your details'), findsOneWidget);
    });

    testWidgets('the primary and secondary actions share one height',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      final reviewHeight =
          tester.getSize(find.widgetWithText(FilledButton, 'Review')).height;
      final backHeight =
          tester.getSize(find.widgetWithText(OutlinedButton, 'Back')).height;

      expect(reviewHeight, greaterThanOrEqualTo(kTouchMin));
      expect(backHeight, greaterThanOrEqualTo(kTouchMin));
      expect(backHeight, closeTo(reviewHeight, 0.01));
    });

    testWidgets('Quick Exit stays available on this step', (tester) async {
      tallPhone(tester);
      await pumpSupport(tester);

      expect(find.byType(QuickExitButton), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('shows the step header, options, and tags in Kiswahili',
        (tester) async {
      tallPhone(tester);
      await pumpSupport(tester, locale: const Locale('sw'));

      expect(find.text('Hatua ya 2 kati ya 3'), findsOneWidget);
      expect(find.text('Nini kingesaidia zaidi?'), findsOneWidget);
      expect(find.text('Tuma bila kuwasiliana na mtu yeyote'), findsOneWidget);
      expect(find.text('Haipatikani · Inatengenezwa'), findsNWidgets(2));
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      tallPhone(tester);
      await pumpSupport(tester, mode: ThemeMode.dark);

      expect(find.text('What would help most?'), findsOneWidget);
      expect(find.byType(SafeSignalTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects reduced motion and still records the choice',
        (tester) async {
      tallPhone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final controller = await pumpSupport(tester);

      await tester.tap(find.text('Submit without contacting anyone'));
      await tester.pumpAndSettle();

      expect(controller.draft.support, SupportOption.private);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kiswahili options fit at 2x text scale on a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpSupport(tester, locale: const Locale('sw'));
      await reveal(tester, find.text('Tuma bila kuwasiliana na mtu yeyote'));

      expect(find.text('Tuma bila kuwasiliana na mtu yeyote'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the step is reachable from the incident step and Back returns '
        'there', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      await tapButton(tester, 'Report an incident');

      await tester.tap(find.text('Unwanted touching'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Continue');

      expect(find.text('Step 2 of 3'), findsOneWidget);

      // Scope the tap to this screen: the step below also has a Back button,
      // and lazy lists only build the rows that are on screen.
      final backButton = find.descendant(
        of: find.byType(SupportScreen),
        matching: find.widgetWithText(OutlinedButton, 'Back'),
      );
      await reveal(tester, backButton);
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SupportScreen), findsNothing);
      expect(find.byType(ReportScreen), findsOneWidget);
    });
  });
}
