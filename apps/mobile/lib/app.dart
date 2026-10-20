import 'package:flutter/material.dart';

import 'api/report_api.dart';
import 'api/submission_controller.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';

class SafeSignalApp extends StatefulWidget {
  const SafeSignalApp({super.key, this.api});

  /// Injected in tests; the real app builds one from `--dart-define=API_BASE_URL`.
  final ReportApi? api;

  @override
  State<SafeSignalApp> createState() => _SafeSignalAppState();
}

class _SafeSignalAppState extends State<SafeSignalApp> {
  // Draft and submission state live in memory only.
  late final SubmissionController _controller =
      SubmissionController(api: widget.api ?? ReportApi());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSignal',
      debugShowCheckedModeBanner: false,
      theme: buildSafeSignalTheme(),
      home: WelcomeScreen(controller: _controller),
    );
  }
}
