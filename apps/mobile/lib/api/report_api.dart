import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/report_draft.dart';

/// Base URL comes from the build: `--dart-define=API_BASE_URL=https://...`. Empty means this
/// build is not connected to any server (nothing is ever sent).
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

sealed class SubmitOutcome {
  const SubmitOutcome();
}

class SubmitAccepted extends SubmitOutcome {
  const SubmitAccepted(this.code);
  final String code;
}

class SubmitRejected extends SubmitOutcome {
  const SubmitRejected();
}

class SubmitRateLimited extends SubmitOutcome {
  const SubmitRateLimited(this.retryAfterSeconds);
  final int? retryAfterSeconds;
}

class SubmitNetworkFailure extends SubmitOutcome {
  const SubmitNetworkFailure({required this.timedOut});
  final bool timedOut;
}

/// 409 (key reused with a different payload), 5xx, or a response we cannot understand.
class SubmitUnexpected extends SubmitOutcome {
  const SubmitUnexpected({this.keyConflict = false});
  final bool keyConflict;
}

class SubmitNotConfigured extends SubmitOutcome {
  const SubmitNotConfigured();
}

/// Talks to `POST /api/reports` (see docs/API.md). Never logs request or response bodies.
class ReportApi {
  ReportApi({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        baseUrl = (baseUrl ?? apiBaseUrl).trim();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  bool get isConfigured => baseUrl.isNotEmpty;

  /// Exact JSON the backend accepts. Fields are trimmed like the web client; the server
  /// upper-cases the plate. No contact details or location are ever included.
  static Map<String, Object?> payload(ReportDraft d) => {
        'incident': d.incident!.apiValue,
        'timing': d.timing.apiValue,
        'route': d.route.trim(),
        'area': d.area.trim(),
        'vehicle': d.vehicle.trim(),
        'sacco': d.sacco.trim(),
        'support': d.support!.apiValue,
        'contactProvided': false,
        'consentToShare': false,
      };

  Future<SubmitOutcome> submit(
    Map<String, Object?> body,
    String idempotencyKey,
  ) async {
    if (!isConfigured) return const SubmitNotConfigured();
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/reports');
    try {
      final res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': idempotencyKey,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _interpret(res);
    } on TimeoutException {
      return const SubmitNetworkFailure(timedOut: true);
    } on SocketException {
      return const SubmitNetworkFailure(timedOut: false);
    } on http.ClientException {
      return const SubmitNetworkFailure(timedOut: false);
    } on HandshakeException {
      return const SubmitNetworkFailure(timedOut: false);
    }
  }

  SubmitOutcome _interpret(http.Response res) {
    switch (res.statusCode) {
      case 200 || 201:
        try {
          final data = jsonDecode(res.body);
          final code = data is Map ? data['code'] : null;
          if (code is String && code.isNotEmpty) return SubmitAccepted(code);
        } on FormatException {
          // fall through
        }
        return const SubmitUnexpected();
      case 409:
        return const SubmitUnexpected(keyConflict: true);
      case 422:
        return const SubmitRejected();
      case 429:
        return SubmitRateLimited(int.tryParse(res.headers['retry-after'] ?? ''));
      default:
        return const SubmitUnexpected();
    }
  }

  void close() => _client.close();
}

/// Random UUID v4. Never derived from report content.
String newIdempotencyKey([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int from, int to) =>
      b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
}
