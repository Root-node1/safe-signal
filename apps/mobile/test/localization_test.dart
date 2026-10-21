import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/app.dart';

import 'helpers.dart';

Map<String, dynamic> arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> keys(Map<String, dynamic> m) =>
    m.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

Future<void> useSwahili(WidgetTester tester) async {
  await tapButton(tester, 'Kiswahili');
  expect(find.text('Ripoti tukio'), findsWidgets);
}

void main() {
  group('translation files', () {
    test('Kiswahili has exactly the same keys and placeholders as English', () {
      final en = arb('en');
      final sw = arb('sw');
      expect(keys(sw), keys(en));
      for (final k in keys(en)) {
        expect(placeholders(sw[k] as String), placeholders(en[k] as String),
            reason: 'placeholders differ for $k');
        expect((sw[k] as String).trim(), isNotEmpty, reason: k);
      }
    });

    test('emergency numbers are identical in both languages', () {
      for (final lang in ['en', 'sw']) {
        final m = arb(lang);
        for (final k in ['notEmergencyBody', 'dangerNote', 'confirmNotice']) {
          final text = m[k] as String;
          expect(text, contains('999'), reason: '$lang $k');
          expect(text, contains('112'), reason: '$lang $k');
        }
        // Helpline numbers live in code, never in translations.
        expect(jsonEncode(m), isNot(contains('1195')));
      }
    });
  });

  group('Kiswahili in the app', () {
    testWidgets('selector switches language on the home screen', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      expect(find.text('Report what is happening now'), findsOneWidget);

      await tapButton(tester, 'Kiswahili');
      expect(find.text('Ripoti kinachotokea sasa'), findsOneWidget);
      expect(find.text('Report what is happening now'), findsNothing);
      expect(find.textContaining('piga 999 au 112'), findsOneWidget);

      await tapButton(tester, 'English');
      expect(find.text('Report what is happening now'), findsOneWidget);
    });

    testWidgets('follows a Swahili phone language', (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('sw', 'KE')];
      await tester.pumpWidget(app());
      expect(find.text('Ripoti kinachotokea sasa'), findsOneWidget);
    });

    testWidgets('unsupported phone language falls back to English', (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('fr', 'FR')];
      await tester.pumpWidget(app());
      expect(find.text('Report what is happening now'), findsOneWidget);
    });

    testWidgets('switching language keeps the draft', (tester) async {
      phone(tester);
      await openReport(tester);
      await tapText(tester, 'Unwanted touching');
      await enterField(tester, 'Route or corridor', 'ZZTEST Route');
      await tapButton(tester, 'Back');

      await useSwahili(tester);
      await tapButton(tester, 'Ripoti tukio');

      expect(find.text('Nini kilitokea?'), findsOneWidget);
      expect(await fieldValue(tester, 'Njia au barabara'), 'ZZTEST Route');
      await reveal(tester, find.text('Kuguswa bila ridhaa yangu'));
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('full flow in Kiswahili sends unchanged English API values',
        (tester) async {
      phone(tester);
      late Map<String, dynamic> sent;
      final api = ReportApi(
        baseUrl: 'http://test.invalid',
        client: MockClient((r) async {
          sent = jsonDecode(r.body) as Map<String, dynamic>;
          return http.Response('{"code":"SS-ABCD-2345"}', 201);
        }),
      );
      await tester.pumpWidget(SafeSignalApp(api: api));
      await useSwahili(tester);
      await tapButton(tester, 'Ripoti kinachotokea sasa');
      await tapText(tester, 'Kuguswa bila ridhaa yangu');
      await enterField(tester, 'Njia au barabara', 'ZZTEST Route');
      await toReview(tester,
          option: 'Onyesha namba za simu za dharura na msaada',
          next: 'Endelea',
          review: 'Kagua');

      expect(find.text('Kagua maelezo yako'), findsOneWidget);
      expect(find.text('Inatokea sasa'), findsOneWidget);
      expect(find.text('Kuguswa bila ridhaa yangu'), findsOneWidget);
      expect(find.text('Haijatolewa'), findsWidgets);

      await tapButton(tester, 'Tuma ripoti');

      expect(find.text('Ripoti imepokelewa'), findsOneWidget);
      expect(find.text('SS-ABCD-2345'), findsOneWidget);
      expect(sent['incident'], 'touching');
      expect(sent['timing'], 'now');
      expect(sent['support'], 'support');
      expect(sent['route'], 'ZZTEST Route');
      await reveal(tester, find.text('1195'));
      expect(find.text('999'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('1195'), findsOneWidget);
      expect(find.text('Polisi na dharura'), findsOneWidget);
    });

    Future<void> failWith(WidgetTester tester, Future<http.Response> Function() f) async {
      phone(tester);
      final api = ReportApi(
        baseUrl: 'http://test.invalid',
        client: MockClient((_) => f()),
      );
      await tester.pumpWidget(SafeSignalApp(api: api));
      await useSwahili(tester);
      await tapButton(tester, 'Ripoti tukio');
      await tapText(tester, 'Kuguswa bila ridhaa yangu');
      await toReview(tester,
          option: 'Tuma bila kuwasiliana na mtu yeyote',
          next: 'Endelea',
          review: 'Kagua');
      await tapButton(tester, 'Tuma ripoti');
    }

    testWidgets('offline error is in Kiswahili and keeps the draft', (tester) async {
      await failWith(tester, () async => throw const SocketException('down'));
      expect(find.textContaining('Imeshindikana kuwasiliana'), findsOneWidget);
      expect(find.text('Ripoti imepokelewa'), findsNothing);
      expect(find.text('Kuguswa bila ridhaa yangu'), findsOneWidget);
    });

    testWidgets('server error is in Kiswahili', (tester) async {
      await failWith(tester, () async => http.Response('x', 500));
      expect(find.textContaining('Hitilafu imetokea kwenye seva'), findsOneWidget);
    });

    testWidgets('validation error is in Kiswahili', (tester) async {
      await failWith(tester, () async => http.Response('{}', 422));
      expect(find.textContaining('Seva haikuweza kupokea'), findsOneWidget);
    });

    testWidgets('rate-limit wait is formatted in Kiswahili', (tester) async {
      await failWith(
          tester, () async => http.Response('{}', 429, headers: {'retry-after': '120'}));
      expect(find.textContaining('subiri dakika 2'), findsOneWidget);
    });

    testWidgets('required-field errors are in Kiswahili', (tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      await useSwahili(tester);
      await tapButton(tester, 'Ripoti tukio');
      await tapButton(tester, 'Endelea');
      expect(find.text('Chagua kilichotokea ili kuendelea.'), findsOneWidget);

      await tapText(tester, 'Kuguswa bila ridhaa yangu');
      await tapButton(tester, 'Endelea');
      await tapButton(tester, 'Kagua');
      expect(find.text('Chagua chaguo linalopatikana ili kuendelea.'), findsOneWidget);
      await tapText(tester, 'Mjulishe mtu ninayemwamini');
      expect(find.text('Haipatikani · Inatengenezwa'), findsNWidgets(2));
    });

    testWidgets('Quick Exit works and is labelled in Kiswahili', (tester) async {
      phone(tester);
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(app());
      await useSwahili(tester);
      await tapButton(tester, 'Ripoti tukio');
      await tapText(tester, 'Kuguswa bila ridhaa yangu');
      await enterField(tester, 'Njia au barabara', 'ZZTEST Route');
      await tapButton(tester, 'Toka');

      expect(calls, contains('SystemNavigator.pop'));
      expect(find.text('Ripoti kinachotokea sasa'), findsOneWidget);
      await tapButton(tester, 'Ripoti tukio');
      expect(await fieldValue(tester, 'Njia au barabara'), '');
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    });

    testWidgets('whole flow survives 2x text scale in Kiswahili', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(app());
      await useSwahili(tester);
      await tapButton(tester, 'Ripoti tukio');
      await tapText(tester, 'Dereva anaendesha kwa hatari');
      await toReview(tester,
          option: 'Tuma bila kuwasiliana na mtu yeyote',
          next: 'Endelea',
          review: 'Kagua');
      await tapButton(tester, 'Tuma ripoti');

      expect(find.text('Ripoti imepokelewa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
