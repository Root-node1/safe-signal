import 'package:flutter/material.dart';

import 'models/report_draft.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';

class SafeSignalApp extends StatefulWidget {
  const SafeSignalApp({super.key});

  @override
  State<SafeSignalApp> createState() => _SafeSignalAppState();
}

class _SafeSignalAppState extends State<SafeSignalApp> {
  // In memory only: cleared when the user finishes or the app closes.
  final ReportDraft _draft = ReportDraft();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSignal',
      debugShowCheckedModeBanner: false,
      theme: buildSafeSignalTheme(),
      home: WelcomeScreen(draft: _draft),
    );
  }
}
