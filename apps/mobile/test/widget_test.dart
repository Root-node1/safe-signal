import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/app.dart';

import 'helpers.dart';

void main() {
  testWidgets('home is honest and offers both entry points', (tester) async {
    phone(tester);
    await tester.pumpWidget(app());

    expect(find.text('Report an incident'), findsWidgets);
    expect(find.text('Report what is happening now'), findsOneWidget);
    expect(find.textContaining('Early prototype'), findsOneWidget);
    expect(find.textContaining('Not an emergency service'), findsOneWidget);
  });

  testWidgets('navigates home -> report -> review -> confirmation', (tester) async {
    phone(tester);
    await openReport(tester);
    expect(find.text('What happened?'), findsOneWidget);

    await tapText(tester, 'Unwanted touching');
    await toReview(tester);
    expect(find.text('Review your details'), findsOneWidget);

    await tapButton(tester, 'Submit report');
    expect(find.text('Report received'), findsOneWidget);
  });

  testWidgets('requires an incident type before reviewing', (tester) async {
    phone(tester);
    await openReport(tester);

    await tapButton(tester, 'Continue');

    expect(find.text('Choose what happened to continue.'), findsOneWidget);
    expect(find.text('What would help most?'), findsNothing);

    await tapText(tester, 'Something else / not sure');
    expect(find.text('Choose what happened to continue.'), findsNothing);
  });

  testWidgets('"happening now" entry preselects timing and shows 999/112 notice',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app());
    await tapButton(tester, 'Report what is happening now');

    expect(find.textContaining('call 999 or 112'), findsOneWidget);
  });

  testWidgets('keeps entered data when going back and forward', (tester) async {
    phone(tester);
    await openReport(tester);

    await tapText(tester, 'Someone is harassing me');
    await enterField(tester, 'Route or corridor', 'Ruiru to CBD');
    await enterField(tester, 'Number plate or matatu name', 'kda 123a');
    await toReview(tester);

    // Back from review lands on the options screen with the choice kept.
    await tapButton(tester, 'Edit details');
    await toTop(tester);
    expect(find.text('What would help most?'), findsOneWidget);
    await tapButton(tester, 'Review');
    await reveal(tester, find.text('Submit without contacting anyone'));
    expect(find.text('Submit without contacting anyone'), findsOneWidget);
    await tapButton(tester, 'Edit details');

    // Back again: report screen still has everything.
    await tapButton(tester, 'Back');
    expect(await fieldValue(tester, 'Route or corridor'), 'Ruiru to CBD');
    expect(await fieldValue(tester, 'Number plate or matatu name'), 'kda 123a');

    // Back to home and into the form again: draft is still there.
    await tapButton(tester, 'Back');
    await tapButton(tester, 'Report an incident');
    expect(await fieldValue(tester, 'Route or corridor'), 'Ruiru to CBD');
  });

  testWidgets('review shows exactly what was entered', (tester) async {
    phone(tester);
    await openReport(tester);

    await tapText(tester, 'The driver is driving dangerously');
    await enterField(tester, 'Route or corridor', 'Thika Road');
    await enterField(tester, 'Number plate or matatu name', 'kda 123a');
    await toReview(tester);

    expect(find.text('The driver is driving dangerously'), findsOneWidget);
    expect(find.text('Thika Road'), findsOneWidget);
    expect(find.text('KDA 123A'), findsOneWidget);
    expect(find.text('Already happened'), findsOneWidget);
    // Fields left blank are labelled, not hidden.
    expect(find.text('Not provided'), findsNWidgets(2));
  });

  testWidgets('confirmation appears only after the server accepts, and is honest',
      (tester) async {
    phone(tester);
    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await toReview(tester);
    expect(find.text('Report received'), findsNothing);
    await tapButton(tester, 'Submit report');

    expect(find.text('Report received'), findsOneWidget);
    expect(find.text('SS-ABCD-2345'), findsOneWidget);
    expect(find.textContaining('has not been'), findsOneWidget);
    expect(find.textContaining('not an emergency service'), findsOneWidget);
    expect(find.textContaining('dispatched'), findsNothing);
    expect(find.textContaining('investigat'), findsNothing);
  });

  testWidgets('without a configured server nothing is sent and no success is shown',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(SafeSignalApp(api: ReportApi(baseUrl: '')));
    await tapButton(tester, 'Report an incident');
    await tapText(tester, 'Unwanted touching');
    await toReview(tester);
    await tapButton(tester, 'Submit report');

    expect(find.text('Report received'), findsNothing);
    expect(find.text('Review your details'), findsOneWidget);
    expect(find.textContaining('not connected to a SafeSignal server'), findsOneWidget);
  });

  testWidgets('a failed submission keeps the details for a retry', (tester) async {
    phone(tester);
    var fail = true;
    final api = ReportApi(
      baseUrl: 'http://test.invalid',
      client: MockClient((_) async => fail
          ? http.Response('oops', 500)
          : http.Response('{"code":"SS-WXYZ-9999"}', 201)),
    );
    await tester.pumpWidget(SafeSignalApp(api: api));
    await tapButton(tester, 'Report an incident');
    await tapText(tester, 'Unwanted touching');
    await enterField(tester, 'Route or corridor', 'Thika Road');
    await toReview(tester);
    await tapButton(tester, 'Submit report');

    expect(find.text('Report received'), findsNothing);
    expect(find.textContaining('not confirmed'), findsOneWidget);
    expect(find.text('Thika Road'), findsOneWidget);

    fail = false;
    await tapButton(tester, 'Submit report');
    expect(find.text('SS-WXYZ-9999'), findsOneWidget);
  });

  testWidgets('Done clears the draft and returns home', (tester) async {
    phone(tester);
    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await enterField(tester, 'Route or corridor', 'Ruiru');
    await toReview(tester);
    await tapButton(tester, 'Submit report');
    await tapButton(tester, 'Done');

    expect(find.text('Report what is happening now'), findsOneWidget);
    await tapButton(tester, 'Report an incident');
    expect(await fieldValue(tester, 'Route or corridor'), '');
  });

  testWidgets('whole flow survives 2x text scale on a small phone', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await toReview(tester);
    await tapButton(tester, 'Submit report');

    expect(find.text('Report received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('support step requires an available option', (tester) async {
    phone(tester);
    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await tapButton(tester, 'Continue');
    expect(find.text('What would help most?'), findsOneWidget);

    await tapButton(tester, 'Review');
    expect(find.text('Choose an available option to continue.'), findsOneWidget);
    expect(find.text('Review your details'), findsNothing);

    // Options still in development cannot be chosen.
    await tapText(tester, 'Alert someone I trust');
    await tapText(tester, 'Ask for a partner check-in');
    await tapButton(tester, 'Review');
    expect(find.text('Review your details'), findsNothing);
    expect(find.text('Unavailable · In development'), findsNWidgets(2));
  });

  testWidgets('chosen support option is shown on review', (tester) async {
    phone(tester);
    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await tapButton(tester, 'Continue');
    await tapText(tester, 'Show emergency and support phone numbers');
    await tapButton(tester, 'Review');

    expect(find.text('What would help most'), findsOneWidget);
    expect(find.text('Show emergency and support phone numbers'), findsOneWidget);
  });

  testWidgets('support-numbers choice lists helplines on confirmation', (tester) async {
    phone(tester);
    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await toReview(tester, option: 'Show emergency and support phone numbers');
    await tapButton(tester, 'Submit report');

    expect(find.text('Report received'), findsOneWidget);
    await reveal(tester, find.text('1195'));
    expect(find.text('1195'), findsOneWidget);
    expect(find.textContaining('does not make calls'), findsOneWidget);
  });

  testWidgets('quick exit clears the draft and asks Android to close', (tester) async {
    phone(tester);
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await openReport(tester);
    await tapText(tester, 'Unwanted touching');
    await tester.enterText(
        find.widgetWithText(TextField, 'Route or corridor'), 'Ruiru');
    await tapButton(tester, 'Exit');

    expect(calls, contains('SystemNavigator.pop'));
    // Back on a blank home screen; reopening the form shows nothing kept.
    expect(find.text('Report what is happening now'), findsOneWidget);
    await tapButton(tester, 'Report an incident');
    expect(await fieldValue(tester, 'Route or corridor'), '');
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
  });

  testWidgets('quick exit is available on every reporting screen', (tester) async {
    phone(tester);
    await openReport(tester);
    expect(find.text('Exit'), findsOneWidget);
    await tapText(tester, 'Unwanted touching');
    await tapButton(tester, 'Continue');
    expect(find.text('Exit'), findsOneWidget);
    await tapText(tester, 'Submit without contacting anyone');
    await tapButton(tester, 'Review');
    expect(find.text('Exit'), findsOneWidget);
    await tapButton(tester, 'Submit report');
    expect(find.text('Exit'), findsOneWidget);
  });
}
