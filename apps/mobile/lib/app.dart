import 'package:flutter/material.dart';

import 'api/report_api.dart';
import 'api/submission_controller.dart';
import 'l10n/l10n.dart';
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
  // Draft and submission state live in memory only, outside the widget tree below, so
  // changing language rebuilds the text without touching the draft or navigation.
  late final SubmissionController _controller =
      SubmissionController(api: widget.api ?? ReportApi());

  /// null = follow the phone's language (Kiswahili if the phone uses it, otherwise English).
  /// The choice is not saved to disk.
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSignal',
      debugShowCheckedModeBanner: false,
      theme: buildSafeSignalTheme(),
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WelcomeScreen(
        controller: _controller,
        onLocaleChanged: (l) => setState(() => _locale = l),
      ),
    );
  }
}
