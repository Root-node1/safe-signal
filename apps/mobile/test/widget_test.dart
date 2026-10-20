import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/app.dart';

void main() {
  testWidgets('welcome screen shows branding and honest status', (tester) async {
    await tester.pumpWidget(const SafeSignalApp());

    expect(find.text('Welcome to SafeSignal'), findsOneWidget);
    expect(find.textContaining('not available in the app yet'), findsOneWidget);
    expect(find.textContaining('not an emergency service'), findsOneWidget);
  });

  testWidgets('layout survives large text scale', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(const SafeSignalApp());

    expect(tester.takeException(), isNull);
  });
}
