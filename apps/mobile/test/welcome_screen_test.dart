// Tests for the Task 4 refactor of WelcomeScreen:
//   - the private `_Notice` class is replaced by the shared `SafeSignalBanner`
//   - spacing and touch targets come from the shared design tokens
//
// The reporting flow itself is covered by widget_test.dart and
// localization_test.dart; these tests only guard the home screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/widgets.dart';

import 'helpers.dart';

/// The [BoxDecoration] of the banner at [index] on the home screen.
BoxDecoration _bannerDecoration(WidgetTester tester, int index) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(SafeSignalBanner).at(index),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows the prototype notice and the not-emergency warning '
        'as SafeSignalBanner widgets', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      final banners = tester
          .widgetList<SafeSignalBanner>(find.byType(SafeSignalBanner))
          .toList();

      expect(banners.length, 2);
      expect(banners[0].variant, SafeSignalBannerVariant.notice);
      expect(banners[0].title, 'Early prototype');
      expect(banners[1].variant, SafeSignalBannerVariant.warning);
      expect(banners[1].title, 'Not an emergency service');
    });

    testWidgets('banner colours come from the token palette', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      expect(
        _bannerDecoration(tester, 0).color,
        SafeSignalColors.amberSubtle,
        reason: 'the prototype notice uses the amber palette',
      );
      expect(
        _bannerDecoration(tester, 1).color,
        SafeSignalColors.coralSubtle,
        reason: 'the not-emergency notice uses the coral palette',
      );
    });

    testWidgets('list padding uses the shared spacing token', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.padding, const EdgeInsets.all(kSpace6));
    });

    testWidgets('both entry points meet the minimum touch target',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      final primary = tester.getSize(
        find.widgetWithText(FilledButton, 'Report an incident'),
      );
      final secondary = tester.getSize(
        find.widgetWithText(TextButton, 'Report what is happening now'),
      );

      expect(primary.height, greaterThanOrEqualTo(kTouchMin));
      expect(secondary.height, greaterThanOrEqualTo(kTouchMin));
    });

    testWidgets('language toggle still switches to Kiswahili and back',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      await tapButton(tester, 'Kiswahili');
      expect(find.text('Toleo la majaribio'), findsOneWidget);
      expect(find.text('Si huduma ya dharura'), findsOneWidget);
      expect(find.text('Ripoti kinachotokea sasa'), findsOneWidget);

      await tapButton(tester, 'English');
      expect(find.text('Early prototype'), findsOneWidget);
      expect(find.text('Report what is happening now'), findsOneWidget);
    });

    testWidgets('hero title is still announced as a heading', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      final nodes = tester.semantics.simulatedAccessibilityTraversal();
      // The AppBar title is a heading too, so look for the hero title among
      // the heading nodes rather than for the first one.
      final headerNodes =
          nodes.where((n) => n.flagsCollection.isHeader).toList();
      expect(
        headerNodes.any((n) => n.label.contains('Report an incident')),
        isTrue,
        reason: 'the hero title must be announced as a heading',
      );
    });

    testWidgets('home banners are static notices, not live regions',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      // Only the error variant of SafeSignalBanner is a live region; the
      // prototype notice and the not-emergency warning on the home screen
      // must stay silent so TalkBack does not announce them on arrival.
      expect(hasLiveRegionNode(tester), isFalse);
    });

    testWidgets('both entry points still open the reporting flow',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(app());

      await tapButton(tester, 'Report an incident');
      expect(find.text('What happened?'), findsOneWidget);

      await tapButton(tester, 'Back');
      await tapButton(tester, 'Report what is happening now');
      expect(find.text('What happened?'), findsOneWidget);
      expect(find.textContaining('call 999 or 112'), findsOneWidget);
    });

    testWidgets('Kiswahili home screen renders without overflow at 2x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(app());
      await tapButton(tester, 'Kiswahili');
      await reveal(tester, find.text('Toleo la majaribio'));

      expect(find.text('Toleo la majaribio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
