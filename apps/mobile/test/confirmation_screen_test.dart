// Tests for the Flutter Confirmation screen
// (lib/screens/confirmation_screen.dart).
//
// Covers the M.3 redesign of this step: the token-driven reference card, the
// amber notice banner, the helpline rows, and the truthfulness of the
// confirmation state (a reference code only ever appears after the server
// confirmed the report).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/design_tokens.dart';
import 'package:safesignal/l10n/l10n.dart';
import 'package:safesignal/models/report_draft.dart';
import 'package:safesignal/screens/confirmation_screen.dart';
import 'package:safesignal/theme.dart';
import 'package:safesignal/widgets/widgets.dart';

import 'helpers.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// A controller whose report the server has already confirmed.
Future<SubmissionController> confirmedController({
  SupportOption support = SupportOption.support,
}) async {
  final controller = SubmissionController(
    api: okApi(),
    draft: ReportDraft()
      ..timing = Timing.after
      ..incident = IncidentType.touching
      ..route = 'Thika Road'
      ..support = support,
  );
  await controller.submit();
  return controller;
}

/// Pumps the Confirmation screen for an already-confirmed [controller].
Future<void> pumpConfirmation(
  WidgetTester tester,
  SubmissionController controller, {
  Locale? locale,
  ThemeMode mode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildSafeSignalTheme(),
      darkTheme: buildSafeSignalDarkTheme(),
      themeMode: mode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ConfirmationScreen(controller: controller),
    ),
  );
}

void main() {
  group('Confirmation screen', () {
    testWidgets('shows the confirmed report and its reference code',
        (tester) async {
      tallPhone(tester);
      await pumpConfirmation(tester, await confirmedController());

      expect(find.text('Report received'), findsOneWidget);
      expect(
        find.text(
          'The SafeSignal server accepted your report. In this prototype, '
          'reports are stored temporarily and may be cleared.',
        ),
        findsOneWidget,
      );
      expect(find.text('Reference code'), findsOneWidget);
      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        find.text('You cannot look this code up yet, and it may stop being valid.'),
        findsOneWidget,
      );
    });

    testWidgets('the copy button puts the reference code on the clipboard',
        (tester) async {
      tallPhone(tester);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpConfirmation(tester, await confirmedController());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Copy code'));
      await tester.pumpAndSettle();

      final copy = calls.where((c) => c.method == 'Clipboard.setData').toList();
      expect(copy.length, 1);
      final args = copy.single.arguments as Map<dynamic, dynamic>;
      expect(args['text'], 'SS-ABCD-2345');
    });

    testWidgets('the amber notice states that nothing has been contacted yet',
        (tester) async {
      tallPhone(tester);
      await pumpConfirmation(tester, await confirmedController());

      expect(find.byType(SafeSignalBanner), findsOneWidget);
      expect(
        find.text(
          'Nobody has been contacted. This report has not been verified, '
          'reviewed, or forwarded, and nothing is saved on your phone. '
          'SafeSignal is not an emergency service. If you are in immediate '
          'danger, call 999 or 112.',
        ),
        findsOneWidget,
      );
      // A notice is static content: it must not interrupt TalkBack.
      expect(hasLiveRegionNode(tester), isFalse);
    });

    testWidgets('helplines are listed when the user asked for support numbers',
        (tester) async {
      tallPhone(tester);
      await pumpConfirmation(
        tester,
        await confirmedController(support: SupportOption.support),
      );

      expect(find.text('Emergency and support numbers'), findsOneWidget);
      expect(
        find.text('Call these yourself. SafeSignal does not make calls.'),
        findsOneWidget,
      );
      expect(find.text('Police and emergency'), findsOneWidget);
      expect(find.text('Emergency (mobile)'), findsOneWidget);
      expect(find.text('National GBV helpline'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('1195'), findsOneWidget);
    });

    testWidgets('helplines are not listed when the user chose to stay private',
        (tester) async {
      tallPhone(tester);
      await pumpConfirmation(
        tester,
        await confirmedController(support: SupportOption.private),
      );

      expect(find.text('Emergency and support numbers'), findsNothing);
      expect(find.text('999'), findsNothing);
      expect(find.text('Report received'), findsOneWidget);
    });

    testWidgets('without a confirmed submission there is no reference code',
        (tester) async {
      tallPhone(tester);
      // A controller that never submitted: nothing was confirmed.
      final controller = SubmissionController(
        api: okApi(),
        draft: ReportDraft()..incident = IncidentType.touching,
      );
      await pumpConfirmation(tester, controller);

      expect(find.text('SS-ABCD-2345'), findsNothing);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Emergency and support numbers'), findsNothing);
    });

    testWidgets('the title and the helpline heading are announced as headings',
        (tester) async {
      tallPhone(tester);
      await pumpConfirmation(
        tester,
        await confirmedController(support: SupportOption.support),
      );

      final headers = tester
          .semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.flagsCollection.isHeader)
          .map((n) => n.label)
          .toList();
      expect(headers, contains('Report received'));
      expect(headers, contains('Emergency and support numbers'));
    });

    testWidgets('the copy and done actions meet the minimum touch target',
        (tester) async {
      tallPhone(tester);
      await pumpConfirmation(tester, await confirmedController());

      final copyHeight =
          tester.getSize(find.widgetWithText(OutlinedButton, 'Copy code')).height;
      final doneHeight =
          tester.getSize(find.widgetWithText(FilledButton, 'Done')).height;

      expect(copyHeight, greaterThanOrEqualTo(kTouchMin));
      expect(doneHeight, greaterThanOrEqualTo(kTouchMin));
    });

    testWidgets('Quick Exit stays available on this step', (tester) async {
      tallPhone(tester);
      await pumpConfirmation(tester, await confirmedController());

      expect(find.byType(QuickExitButton), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('shows every string in Kiswahili', (tester) async {
      tallPhone(tester);
      await pumpConfirmation(
        tester,
        await confirmedController(support: SupportOption.support),
        locale: const Locale('sw'),
      );

      expect(find.text('Ripoti imepokelewa'), findsOneWidget);
      expect(find.text('Namba ya kumbukumbu'), findsOneWidget);
      expect(find.text('Nakili namba'), findsOneWidget);
      expect(find.text('Namba za dharura na msaada'), findsOneWidget);
      expect(find.text('Polisi na dharura'), findsOneWidget);
      expect(
        find.text(
          'Hakuna mtu aliyewasiliwa. Ripoti hii haijathibitishwa, kukaguliwa, '
          'wala kupelekwa kwingine, na hakuna kinachohifadhiwa kwenye simu yako. '
          'SafeSignal si huduma ya dharura. Ukiwa katika hatari ya haraka, '
          'piga 999 au 112.',
        ),
        findsOneWidget,
      );
      expect(find.text('Nimemaliza'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      tallPhone(tester);
      await pumpConfirmation(
        tester,
        await confirmedController(support: SupportOption.support),
        mode: ThemeMode.dark,
      );

      expect(find.text('Report received'), findsOneWidget);
      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kiswahili confirmation fits at 2x text scale on a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpConfirmation(
        tester,
        await confirmedController(support: SupportOption.support),
        locale: const Locale('sw'),
      );
      await reveal(tester, find.text('SS-ABCD-2345'));

      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Done returns to the welcome screen with the draft cleared',
        (tester) async {
      phone(tester);
      await openReport(tester);
      await tapText(tester, 'Unwanted touching');
      await toReview(tester);
      await tapButton(tester, 'Submit report');

      expect(find.text('Report received'), findsOneWidget);

      await tapButton(tester, 'Done');

      expect(find.text('Report what is happening now'), findsOneWidget);
      await tapButton(tester, 'Report an incident');
      expect(await fieldValue(tester, 'Route or corridor'), '');
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    });

    testWidgets('the Android Back button behaves like Done', (tester) async {
      phone(tester);
      await openReport(tester);
      await tapText(tester, 'Unwanted touching');
      await toReview(tester);
      await tapButton(tester, 'Submit report');

      expect(find.text('Report received'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Back from the confirmation never returns to the review step.
      expect(find.text('Report what is happening now'), findsOneWidget);
      expect(find.text('Review your details'), findsNothing);
    });
  });
}
