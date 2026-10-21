// Tests for the Task 3 reusable widgets:
//   SafeSignalTile, StepHeader, SafeSignalBanner.
//
// Each widget is wrapped in a minimal MaterialApp with the SafeSignal themes
// so ThemeData / ColorScheme / TextTheme are fully resolved.
// No real screens or navigation are involved.

import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/safesignal_banner.dart';
import 'package:safesignal/widgets/safesignal_tile.dart';
import 'package:safesignal/widgets/step_header.dart';

import 'helpers.dart';

// ─── Test helper ──────────────────────────────────────────────────────────────

/// Wraps [child] in a minimal [MaterialApp] using the SafeSignal themes.
Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.light}) {
  return MaterialApp(
    theme: buildSafeSignalTheme(),
    darkTheme: buildSafeSignalDarkTheme(),
    themeMode: mode,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // SafeSignalTile
  // ═══════════════════════════════════════════════════════════════════════════

  group('SafeSignalTile', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Unwanted touching',
          selected: false,
          onTap: () {},
        ),
      ));
      expect(find.text('Unwanted touching'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Unwanted touching',
          subtitle: 'Non-consensual physical contact.',
          selected: false,
          onTap: () {},
        ),
      ));
      expect(find.text('Non-consensual physical contact.'), findsOneWidget);
    });

    testWidgets('shows unchecked icon when not selected', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Harassment',
          selected: false,
          onTap: () {},
        ),
      ));
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    });

    testWidgets('shows checked icon when selected', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Harassment',
          selected: true,
          onTap: () {},
        ),
      ));
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    });

    testWidgets('calls onTap when tapped while enabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Threats',
          selected: false,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Threats'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('does not fire onTap when disabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Alert someone I trust',
          selected: false,
          enabled: false,
          onTap: () => tapped = true,
        ),
      ));
      // warnIfMissed: false because InkWell is still present but disabled.
      await tester.tap(
        find.text('Alert someone I trust'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('shows badge when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Trusted contact',
          badge: 'Unavailable · In development',
          selected: false,
          enabled: false,
          onTap: null,
        ),
      ));
      expect(find.text('Unavailable · In development'), findsOneWidget);
    });

    testWidgets('meets minimum touch-target height (kTouchMin)', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Short title',
          selected: false,
          onTap: () {},
        ),
      ));
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        container.constraints?.minHeight ?? 0.0,
        greaterThanOrEqualTo(kTouchMin),
      );
    });

    testWidgets('selected tile has inMutuallyExclusiveGroup semantics',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Followed',
          subtitle: 'Someone tailing you.',
          selected: true,
          onTap: () {},
        ),
      ));
      // getSemantics on the merged node — use the Semantics widget directly
      // since byType(SafeSignalTile) resolves to a parent container node.
      // The tile's Semantics wrapper produces one merged node with these flags.
      final semanticsNodes = tester.semantics.simulatedAccessibilityTraversal();
      final tileNode = semanticsNodes.firstWhere(
        (n) => n.flagsCollection.isInMutuallyExclusiveGroup,
        orElse: () => throw TestFailure(
          'No node with isInMutuallyExclusiveGroup found in semantics tree',
        ),
      );
      expect(tileNode.flagsCollection.isChecked, CheckedState.isTrue);
    });

    testWidgets('unselected tile is not checked in semantics', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Dangerous driving',
          selected: false,
          onTap: () {},
        ),
      ));
      final semanticsNodes = tester.semantics.simulatedAccessibilityTraversal();
      final tileNode = semanticsNodes.firstWhere(
        (n) => n.flagsCollection.isInMutuallyExclusiveGroup,
        orElse: () => throw TestFailure(
          'No node with isInMutuallyExclusiveGroup found in semantics tree',
        ),
      );
      expect(tileNode.flagsCollection.isChecked, isNot(CheckedState.isTrue));
    });

    testWidgets('semanticLabel override replaces default label', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Something else',
          subtitle: 'Unusual disturbance.',
          selected: false,
          onTap: () {},
          semanticLabel: 'Custom TalkBack label',
        ),
      ));
      final semanticsNodes = tester.semantics.simulatedAccessibilityTraversal();
      final tileNode = semanticsNodes.firstWhere(
        (n) => n.flagsCollection.isInMutuallyExclusiveGroup,
        orElse: () => throw TestFailure(
          'No node with isInMutuallyExclusiveGroup found',
        ),
      );
      expect(tileNode.label, 'Custom TalkBack label');
    });

    testWidgets('renders a leading widget when supplied', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'With icon',
          leading: const Icon(Icons.warning_amber, key: Key('tile-icon')),
          selected: false,
          onTap: () {},
        ),
      ));
      expect(find.byKey(const Key('tile-icon')), findsOneWidget);
    });

    testWidgets('builds without error when disableAnimations is true',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Reduced motion tile',
          selected: false,
          onTap: () {},
        ),
      ));
      expect(find.text('Reduced motion tile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(_wrap(
        SafeSignalTile(
          title: 'Dark tile',
          selected: false,
          onTap: () {},
        ),
        mode: ThemeMode.dark,
      ));
      expect(find.text('Dark tile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // StepHeader
  // ═══════════════════════════════════════════════════════════════════════════

  group('StepHeader', () {
    testWidgets('renders stepLabel and title', (tester) async {
      await tester.pumpWidget(_wrap(
        const StepHeader(
          stepLabel: 'Step 1 of 3',
          title: 'What happened?',
        ),
      ));
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('What happened?'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const StepHeader(
          stepLabel: 'Step 2 of 3',
          title: 'Details',
          subtitle: 'All fields are optional.',
        ),
      ));
      expect(find.text('All fields are optional.'), findsOneWidget);
    });

    testWidgets('does not render a subtitle Text when subtitle is null',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const StepHeader(
          stepLabel: 'Step 3 of 3',
          title: 'What would help most?',
        ),
      ));
      // stepLabel + title = 2 Text widgets; no third one.
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('title carries isHeader semantics for TalkBack', (tester) async {
      await tester.pumpWidget(_wrap(
        const StepHeader(
          stepLabel: 'Step 1 of 3',
          title: 'What happened?',
        ),
      ));
      final semanticsNodes = tester.semantics.simulatedAccessibilityTraversal();
      final headerNode = semanticsNodes.firstWhere(
        (n) => n.flagsCollection.isHeader,
        orElse: () => throw TestFailure(
          'No node with isHeader found in semantics tree',
        ),
      );
      expect(headerNode.label, contains('What happened?'));
    });

    testWidgets('renders without overflow at 2x text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(_wrap(
        const StepHeader(
          stepLabel: 'Step 1 of 3',
          title: 'What happened?',
          subtitle: 'Choose the category that best fits your situation.',
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(_wrap(
        const StepHeader(
          stepLabel: 'Hatua ya 2 kati ya 3',
          title: 'Maelezo',
        ),
        mode: ThemeMode.dark,
      ));
      expect(find.text('Maelezo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SafeSignalBanner
  // ═══════════════════════════════════════════════════════════════════════════

  group('SafeSignalBanner', () {
    testWidgets('notice variant renders title and body', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.notice,
          title: 'Early prototype',
          body: 'Reports are stored temporarily.',
        ),
      ));
      expect(find.text('Early prototype'), findsOneWidget);
      expect(find.text('Reports are stored temporarily.'), findsOneWidget);
    });

    testWidgets('warning variant with empty title shows only body', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.warning,
          title: '',
          body: 'Call 999 or 112 if in immediate danger.',
        ),
      ));
      expect(find.text('Call 999 or 112 if in immediate danger.'), findsOneWidget);
      // Title is suppressed when empty; exactly one Text widget.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('error variant renders title and body', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: 'Submission failed',
          body: 'Check your connection and try again.',
        ),
      ));
      expect(find.text('Submission failed'), findsOneWidget);
      expect(find.text('Check your connection and try again.'), findsOneWidget);
    });

    testWidgets('error variant is a live region (TalkBack auto-announce)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: '',
          body: 'Could not reach SafeSignal.',
        ),
      ));
      // Walk the semantics tree looking for a node with isLiveRegion.
      // ensureSemantics() is not required — pumpWidget builds the tree.
      expect(hasLiveRegionNode(tester), isTrue,
          reason: 'Expected a live-region Semantics node for error banners');
    });

    testWidgets('notice variant is NOT a live region', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.notice,
          title: 'Prototype',
          body: 'Data may be cleared.',
        ),
      ));
      expect(hasLiveRegionNode(tester), isFalse,
          reason: 'notice banner should not be a live region');
    });

    testWidgets('warning variant is NOT a live region', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.warning,
          title: 'Not an emergency service',
          body: 'SafeSignal cannot send help.',
        ),
      ));
      expect(hasLiveRegionNode(tester), isFalse,
          reason: 'warning banner should not be a live region');
    });

    testWidgets('error variant has a border decoration', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: '',
          body: 'Error.',
        ),
      ));
      final container =
          tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('notice variant has no border decoration', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.notice,
          title: '',
          body: 'Notice.',
        ),
      ));
      final container =
          tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('titleColor override is applied to title text', (tester) async {
      const customColor = Color(0xFF123456);
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.notice,
          title: 'Custom title',
          body: 'Body.',
          titleColor: customColor,
        ),
      ));
      final titleWidget = tester.widget<Text>(find.text('Custom title'));
      expect(titleWidget.style?.color, customColor);
    });

    testWidgets('renders correctly in dark mode without errors', (tester) async {
      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: 'Dark error',
          body: 'An error occurred.',
        ),
        mode: ThemeMode.dark,
      ));
      expect(find.text('Dark error'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 2x text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(_wrap(
        const SafeSignalBanner(
          variant: SafeSignalBannerVariant.warning,
          title: 'Not an emergency service',
          body:
              'SafeSignal does not contact police or anyone else, and does not '
              'monitor routes or verify reports. If you are in immediate danger, '
              'call 999 or 112.',
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
