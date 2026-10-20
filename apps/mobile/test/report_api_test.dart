import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/models/report_draft.dart';

ReportDraft draft() => ReportDraft()
  ..timing = Timing.now
  ..incident = IncidentType.dangerousDriving
  ..support = SupportOption.support
  ..route = '  Thika Road '
  ..vehicle = 'kda 123a'
  ..sacco = 'Super Metro'
  ..area = 'Githurai 45';

ReportApi apiWith(Future<http.Response> Function(http.Request) h,
        {Duration timeout = const Duration(seconds: 2)}) =>
    ReportApi(
        baseUrl: 'https://api.example.test/',
        client: MockClient(h),
        timeout: timeout);

http.Response created([String code = 'SS-ABCD-2345']) =>
    http.Response(jsonEncode({'id': 'a', 'code': code}), 201);

void main() {
  group('ReportApi', () {
    test('sends POST /api/reports with the exact contract and key header', () async {
      late http.Request seen;
      final api = apiWith((r) async {
        seen = r;
        return created();
      });
      final out = await api.submit(ReportApi.payload(draft()), 'key-1');

      expect(out, isA<SubmitAccepted>());
      expect((out as SubmitAccepted).code, 'SS-ABCD-2345');
      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://api.example.test/api/reports');
      expect(seen.headers['Idempotency-Key'], 'key-1');
      expect(seen.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(seen.body), {
        'incident': 'dangerous-driving',
        'timing': 'now',
        'route': 'Thika Road',
        'area': 'Githurai 45',
        'vehicle': 'kda 123a',
        'sacco': 'Super Metro',
        'support': 'support',
        'contactProvided': false,
        'consentToShare': false,
      });
    });

    test('maps every incident type, timing and support value to the API strings', () {
      expect(IncidentType.values.map((e) => e.apiValue), [
        'harassment', 'threats', 'touching', 'followed', 'dangerous-driving', 'unsure'
      ]);
      expect(Timing.values.map((e) => e.apiValue), ['now', 'after']);
      expect(SupportOption.values.map((e) => e.apiValue),
          ['private', 'support', 'trusted-contact', 'check-in']);
    });

    test('blank optional fields are sent as empty strings', () {
      final d = ReportDraft()
        ..incident = IncidentType.unsure
        ..support = SupportOption.private;
      final p = ReportApi.payload(d);
      expect([p['route'], p['area'], p['vehicle'], p['sacco']], ['', '', '', '']);
      expect(p['timing'], 'after');
    });

    test('status codes map to outcomes', () async {
      Future<SubmitOutcome> go(http.Response r) =>
          apiWith((_) async => r).submit({}, 'k');
      expect(await go(http.Response('{}', 422)), isA<SubmitRejected>());
      expect(await go(http.Response('{}', 409)),
          isA<SubmitUnexpected>().having((o) => o.keyConflict, 'conflict', true));
      expect(await go(http.Response('x', 500)), isA<SubmitUnexpected>());
      expect(await go(http.Response('x', 503)), isA<SubmitUnexpected>());
      final rl = await go(http.Response('{}', 429, headers: {'retry-after': '42'}));
      expect((rl as SubmitRateLimited).retryAfterSeconds, 42);
    });

    test('2xx without a usable code is not treated as success', () async {
      for (final body in ['not json', '{}', '{"code":""}', '{"code":5}', '[]']) {
        final out = await apiWith((_) async => http.Response(body, 201)).submit({}, 'k');
        expect(out, isA<SubmitUnexpected>(), reason: body);
      }
    });

    test('timeout and offline are network failures', () async {
      final slow = apiWith((_) => Completer<http.Response>().future,
          timeout: const Duration(milliseconds: 30));
      expect(await slow.submit({}, 'k'),
          isA<SubmitNetworkFailure>().having((o) => o.timedOut, 'timedOut', true));

      final offline = apiWith((_) async => throw const SocketException('down'));
      expect(await offline.submit({}, 'k'),
          isA<SubmitNetworkFailure>().having((o) => o.timedOut, 'timedOut', false));
    });

    test('unconfigured base URL sends nothing', () async {
      var called = false;
      final api = ReportApi(
          baseUrl: '',
          client: MockClient((_) async {
            called = true;
            return created();
          }));
      expect(await api.submit({}, 'k'), isA<SubmitNotConfigured>());
      expect(called, isFalse);
    });

    test('idempotency keys look like random UUIDs and differ', () {
      final a = newIdempotencyKey();
      final b = newIdempotencyKey();
      expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(a, isNot(b));
    });
  });

  group('SubmissionController', () {
    test('success clears the draft and exposes the code', () async {
      final c = SubmissionController(api: apiWith((_) async => created()), draft: draft());
      await c.submit();
      expect(c.state, isA<Succeeded>().having((s) => s.code, 'code', 'SS-ABCD-2345'));
      expect(c.draft.incident, isNull);
      expect(c.draft.route, '');
      expect(c.currentKey, isNull);
    });

    test('failure keeps the draft and never reports success', () async {
      final c = SubmissionController(
          api: apiWith((_) async => http.Response('x', 500)), draft: draft());
      await c.submit();
      expect(c.state, isA<UnexpectedResponse>());
      expect(c.draft.route, '  Thika Road ');
      expect(c.draft.incident, IncidentType.dangerousDriving);
    });

    test('validation failure is reported and the draft is kept', () async {
      final c = SubmissionController(
          api: apiWith((_) async => http.Response('{}', 422)), draft: draft());
      await c.submit();
      expect(c.state, isA<ValidationFailed>());
      expect(c.draft.sacco, 'Super Metro');
    });

    test('unchanged retry reuses the same key; an edit gets a new one', () async {
      final keys = <String?>[];
      final c = SubmissionController(
        api: apiWith((r) async {
          keys.add(r.headers['Idempotency-Key']);
          throw const SocketException('down');
        }),
        draft: draft(),
      );
      await c.submit();
      await c.submit(); // plain retry
      c.draft.route = 'Jogoo Road'; // edit after failure
      await c.submit();
      await c.submit();

      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[1]));
      expect(keys[2], keys[3]);
    });

    test('a retry that succeeds still sends the original key', () async {
      final keys = <String?>[];
      var n = 0;
      final c = SubmissionController(
        api: apiWith((r) async {
          keys.add(r.headers['Idempotency-Key']);
          return ++n == 1 ? throw TimeoutException('slow') : created();
        }),
        draft: draft(),
      );
      await c.submit();
      expect(c.state, isA<NetworkFailed>().having((s) => s.timedOut, 'timedOut', true));
      await c.submit();
      expect(keys[0], keys[1]);
      expect(c.state, isA<Succeeded>());
    });

    test('rapid double tap sends one request', () async {
      var calls = 0;
      final gate = Completer<http.Response>();
      final c = SubmissionController(
        api: apiWith((_) {
          calls++;
          return gate.future;
        }),
        draft: draft(),
      );
      final first = c.submit();
      final second = c.submit();
      expect(c.isSubmitting, isTrue);
      gate.complete(created());
      await Future.wait([first, second]);
      expect(calls, 1);
      expect(c.state, isA<Succeeded>());
    });

    test('key conflict forces a fresh key on the next attempt', () async {
      final keys = <String?>[];
      var n = 0;
      final c = SubmissionController(
        api: apiWith((r) async {
          keys.add(r.headers['Idempotency-Key']);
          return ++n == 1 ? http.Response('{}', 409) : created();
        }),
        draft: draft(),
      );
      await c.submit();
      expect(c.state, isA<UnexpectedResponse>());
      await c.submit();
      expect(keys[1], isNot(keys[0]));
    });

    test('rate limit exposes Retry-After and keeps the draft', () async {
      final c = SubmissionController(
          api: apiWith((_) async => http.Response('{}', 429, headers: {'retry-after': '90'})),
          draft: draft());
      await c.submit();
      expect(c.state, isA<RateLimited>().having((s) => s.retryAfterSeconds, 's', 90));
      expect(c.draft.incident, isNotNull);
    });

    test('reset (Quick Exit) clears draft, key and ignores a late response', () async {
      final gate = Completer<http.Response>();
      final c = SubmissionController(api: apiWith((_) => gate.future), draft: draft());
      final pending = c.submit();
      c.reset();
      gate.complete(created());
      await pending;
      expect(c.state, isA<Idle>());
      expect(c.draft.incident, isNull);
      expect(c.currentKey, isNull);
    });
  });
}
