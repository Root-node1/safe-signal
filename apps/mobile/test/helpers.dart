import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/app.dart';

/// Fake server: always accepts and returns a reference code. No real network.
ReportApi okApi() => ReportApi(
      baseUrl: 'http://test.invalid',
      client: MockClient((_) async => http.Response(
          '{"code":"SS-ABCD-2345","id":"x","status":"Received"}', 201)),
    );

Widget app() => SafeSignalApp(api: okApi());

void phone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Future<void> tapText(WidgetTester tester, String text) async {
  // Lazy lists only build visible rows, so scroll until the text exists.
  await reveal(tester, find.text(text));
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String value) async {
  final f = find.widgetWithText(TextField, label);
  await reveal(tester, f);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.enterText(f, value);
}

/// Lazy lists only build visible rows: look from the current position, then from the top
/// down, until [f] exists.
Future<void> reveal(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 15 && f.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  if (f.evaluate().isNotEmpty) return;
  await toTop(tester);
  for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
}

Future<void> toTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).last, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

Future<String> fieldValue(WidgetTester tester, String label) async {
  final f = find.widgetWithText(TextField, label);
  await reveal(tester, f);
  return tester.widget<TextField>(f).controller!.text;
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final f = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  await reveal(tester, f);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Report screen -> Continue -> pick an option -> Review.
Future<void> toReview(WidgetTester tester,
    {String option = 'Submit without contacting anyone',
    String next = 'Continue',
    String review = 'Review'}) async {
  await tapButton(tester, next);
  await tapText(tester, option);
  await tapButton(tester, review);
}

Future<void> openReport(WidgetTester tester) async {
  await tester.pumpWidget(app());
  await tapButton(tester, 'Report an incident');
}

/// A tall viewport so every widget on a long reporting step is laid out and
/// can be found without scrolling.
void tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// The root of the semantics tree for the test's render view.
///
/// The render view's [PipelineOwner] owns the [SemanticsOwner] for that view.
/// (`RendererBinding.pipelineOwner` is deprecated.)
SemanticsNode rootSemanticsNode(WidgetTester tester) {
  final renderView = tester.binding.renderViews.firstWhere(
    (view) => view.flutterView == tester.view,
  );
  return renderView.owner!.semanticsOwner!.rootSemanticsNode!;
}

/// Whether any node in the semantics tree is a live region.
bool hasLiveRegionNode(WidgetTester tester) {
  bool found = false;
  void walk(SemanticsNode node) {
    if (node.flagsCollection.isLiveRegion) {
      found = true;
      return;
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(rootSemanticsNode(tester));
  return found;
}
