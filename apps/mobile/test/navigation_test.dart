// Tests for the Flutter screen transitions (lib/navigation.dart).
//
// The route transition is a fade + small upward slide using the shared motion
// tokens.  It must be invisible to anyone who asked for reduced motion, and it
// must not slow down Quick Exit.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/navigation.dart';
import 'package:safesignal/screens/report_screen.dart';

import 'helpers.dart';

/// Holds the route that [pumpPusher] pushed, so its timings can be inspected.
class PushedRoute {
  TransitionRoute<void>? route;
}

/// Pumps a one-button app that pushes a second screen through [appRoute].
Future<PushedRoute> pumpPusher(WidgetTester tester) async {
  final pushed = PushedRoute();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              final route = appRoute<void>(
                context,
                (_) => const Scaffold(body: Text('Second screen')),
              );
              pushed.route = route as TransitionRoute<void>;
              Navigator.of(context).push(route);
            },
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  return pushed;
}

void main() {
  group('appRoute', () {
    testWidgets('uses the shared motion tokens for the transition',
        (tester) async {
      phone(tester);
      final pushed = await pumpPusher(tester);

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pushed.route?.transitionDuration, kDurationSlow);
      expect(pushed.route?.reverseTransitionDuration, kDurationBase);
    });

    testWidgets('fades and slides the next screen in', (tester) async {
      phone(tester);
      await pumpPusher(tester);

      await tester.tap(find.text('go'));
      // First frame starts the route, second builds the page it fades in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Part way through the transition the new page is still fading in and
      // has not reached its final position yet.  Scope the finders to the
      // pushed page: the route below has transitions of its own.
      final fade = find.ancestor(
        of: find.text('Second screen'),
        matching: find.byType(FadeTransition),
      );
      final slide = find.ancestor(
        of: find.text('Second screen'),
        matching: find.byType(SlideTransition),
      );
      expect(fade, findsOneWidget);
      expect(slide, findsOneWidget);

      expect(tester.widget<FadeTransition>(fade).opacity.value, greaterThan(0.0));
      expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1.0));
      expect(
        tester.widget<SlideTransition>(slide).position.value.dy,
        greaterThan(0.0),
      );

      await tester.pumpAndSettle();

      expect(find.text('Second screen'), findsOneWidget);
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1.0);
      expect(
        tester.widget<SlideTransition>(slide).position.value,
        Offset.zero,
      );
    });

    testWidgets('is instant when the user asked for reduced motion',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final pushed = await pumpPusher(tester);

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(pushed.route?.transitionDuration, Duration.zero);
      expect(pushed.route?.reverseTransitionDuration, Duration.zero);
      // No fade, no slide, nothing to animate on the pushed page.
      expect(
        find.ancestor(
          of: find.text('Second screen'),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('Second screen'),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      expect(find.text('Second screen'), findsOneWidget);
    });

    testWidgets('the reporting flow still navigates and keeps the draft',
        (tester) async {
      phone(tester);
      await openReport(tester);
      await tapText(tester, 'Unwanted touching');
      await enterField(tester, 'Route or corridor', 'Thika Road');
      await tapButton(tester, 'Continue');
      await tapText(tester, 'Submit without contacting anyone');
      await tapButton(tester, 'Review');

      expect(find.text('Review your details'), findsOneWidget);
      expect(find.text('Thika Road'), findsOneWidget);

      await tapButton(tester, 'Submit report');

      expect(find.text('Report received'), findsOneWidget);
    });
  });

  group('Quick Exit', () {
    testWidgets('asks the system to close without waiting for a transition',
        (tester) async {
      phone(tester);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await openReport(tester);
      // Start the push and leave the transition running.
      await tester.pump();

      await tester.tap(find.text('Exit'));
      // A single frame: far shorter than the reverse transition.
      await tester.pump();

      expect(
        calls.map((c) => c.method),
        contains('SystemNavigator.pop'),
        reason: 'the exit request must not wait for the route transition',
      );
      // Back on the first route.
      expect(find.text('Report what is happening now'), findsOneWidget);
    });

    testWidgets('closes immediately when reduced motion is on', (tester) async {
      phone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await openReport(tester);
      await tester.pump();

      await tester.tap(find.text('Exit'));
      await tester.pump();

      expect(calls.map((c) => c.method), contains('SystemNavigator.pop'));
      // The popped screen is gone at once: no transition to wait for.
      expect(find.byType(ReportScreen), findsNothing);
      expect(find.text('Report what is happening now'), findsOneWidget);
    });
  });
}
