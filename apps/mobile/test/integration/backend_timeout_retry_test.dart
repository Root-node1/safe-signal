// Opt-in integration test: real Flutter client + real FastAPI process, in-memory storage,
// loopback only, synthetic data. Run with:
//   SAFESIGNAL_BACKEND_IT=1 flutter test test/integration
// It freezes the server (SIGSTOP) so the client genuinely times out, resumes it (SIGCONT)
// so the first request is accepted late, then retries the unchanged report.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safesignal/api/report_api.dart';
import 'package:safesignal/api/submission_controller.dart';
import 'package:safesignal/models/report_draft.dart';

const _adminKey = 'it-admin-key-not-a-secret';

Future<List<dynamic>> _stored(int port) async {
  final c = HttpClient();
  try {
    final req = await c.getUrl(Uri.parse('http://127.0.0.1:$port/api/reports'));
    req.headers.set('X-Admin-Key', _adminKey);
    final res = await req.close();
    return jsonDecode(await res.transform(utf8.decoder).join()) as List<dynamic>;
  } finally {
    c.close(force: true);
  }
}

void main() {
  final enabled = Platform.environment['SAFESIGNAL_BACKEND_IT'] == '1';
  final uvicorn = File('../backend/venv/bin/uvicorn');

  test(
    'timeout, late acceptance, unchanged retry: same key, original code, one report',
    () async {
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();

      final server = await Process.start(
        uvicorn.absolute.path,
        ['main:app', '--host', '127.0.0.1', '--port', '$port'],
        workingDirectory: Directory('../backend').absolute.path,
        includeParentEnvironment: false, // no DATABASE_URL: in-memory mode only
        environment: {
          'SAFESIGNAL_ADMIN_KEY': _adminKey,
          'SAFESIGNAL_REPORT_RATE_LIMIT': '50',
        },
      );
      server.stdout.drain<void>();
      server.stderr.drain<void>();
      var stopped = false;

      try {
        // Wait for readiness and confirm in-memory mode.
        final hc = HttpClient();
        var ready = false;
        for (var i = 0; i < 50 && !ready; i++) {
          try {
            final r = await (await hc.getUrl(
                    Uri.parse('http://127.0.0.1:$port/health/ready')))
                .close();
            final body = await r.transform(utf8.decoder).join();
            ready = r.statusCode == 200 && body.contains('"storage":"memory"');
          } on SocketException {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
        }
        hc.close(force: true);
        expect(ready, isTrue, reason: 'backend did not start in memory mode');

        final controller = SubmissionController(
          api: ReportApi(
            baseUrl: 'http://127.0.0.1:$port',
            timeout: const Duration(seconds: 1),
          ),
          draft: ReportDraft()
            ..timing = Timing.after
            ..incident = IncidentType.unsure
            ..support = SupportOption.private
            ..route = 'ZZTEST Route'
            ..vehicle = 'KZZ 000Z'
            ..sacco = 'ZZTEST Sacco'
            ..area = 'ZZTEST Stage',
        );

        // 1. Freeze the server: the connection is accepted by the OS but never answered.
        Process.killPid(server.pid, ProcessSignal.sigstop);
        stopped = true;
        await controller.submit();
        expect(controller.state, isA<NetworkFailed>().having((s) => s.timedOut, 'timedOut', true));
        final firstKey = controller.currentKey;
        expect(firstKey, isNotNull);
        expect(controller.draft.route, 'ZZTEST Route', reason: 'draft kept after timeout');

        // 2. Resume: the first request is now processed even though the client gave up.
        Process.killPid(server.pid, ProcessSignal.sigcont);
        stopped = false;
        List<dynamic> stored = [];
        for (var i = 0; i < 50 && stored.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          stored = await _stored(port);
        }
        expect(stored, hasLength(1), reason: 'first request was accepted late');
        final originalCode = (stored.single as Map)['code'] as String;

        // 3. Unchanged retry: same key is still held, and the server returns the original report.
        expect(controller.currentKey, firstKey);
        await controller.submit();
        expect(controller.state, isA<Succeeded>());
        expect((controller.state as Succeeded).code, originalCode);

        // 4. Still exactly one stored report.
        expect(await _stored(port), hasLength(1));
      } finally {
        if (stopped) Process.killPid(server.pid, ProcessSignal.sigcont);
        server.kill();
        await server.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
          server.kill(ProcessSignal.sigkill);
          return -1;
        });
      }
    },
    skip: !enabled
        ? 'set SAFESIGNAL_BACKEND_IT=1 to run against a local backend'
        : !uvicorn.existsSync()
            ? 'backend venv not found at ../backend/venv'
            : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
