import 'package:flutter/material.dart';

import 'api/report_api.dart';
import 'api/submission_controller.dart';
import 'l10n/l10n.dart';
import 'storage/pending_draft_store.dart';
import 'storage/secure_pending_draft_store.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';

class SafeSignalApp extends StatefulWidget {
  const SafeSignalApp({
    super.key,
    this.api,
    this.pendingStore,
    this.clock,
  });

  /// Injected in tests; the real app builds one from `--dart-define=API_BASE_URL`.
  final ReportApi? api;

  /// Injected in tests; used to override the default [SecurePendingDraftStore].
  final PendingDraftStore? pendingStore;

  /// Injected in tests; used to override the default [DateTime.now] clock.
  final PendingDraftClock? clock;

  @override
  State<SafeSignalApp> createState() => _SafeSignalAppState();
}

class _SafeSignalAppState extends State<SafeSignalApp> {
  // Draft and submission state live in memory only, outside the widget tree below, so
  // changing language rebuilds the text without touching the draft or navigation.
  late final SubmissionController _controller =
      SubmissionController(
        api: widget.api ?? ReportApi(),
        pendingStore: widget.pendingStore ?? SecurePendingDraftStore(),
        clock: widget.clock,
      );

  /// null = follow the phone's language (Kiswahili if the phone uses it, otherwise English).
  /// The choice is not saved to disk.
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    // Trigger the one-time startup read after the first frame; result cached in
    // _controller.pendingOutcome so WelcomeScreen does not re-read (T-16).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.readPendingReport(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSignal',
      debugShowCheckedModeBanner: false,
      theme: buildSafeSignalTheme(),
      darkTheme: buildSafeSignalDarkTheme(),
      themeMode: ThemeMode.system,
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
