import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/quick_exit_button.dart';
import 'confirmation_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.controller});

  final SubmissionController controller;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  SubmissionController get _c => widget.controller;
  ReportDraft get _d => _c.draft;

  @override
  void initState() {
    super.initState();
    _c.acknowledgeFailure();
    _c.addListener(_onChange);
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    if (_c.state is Succeeded) {
      Navigator.of(context).push(
        appRoute<void>(context, (_) => ConfirmationScreen(controller: _c)),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final submitting = _c.isSubmitting;
    final rows = <(String, String)>[
      ('When', _d.timing == Timing.now ? 'Happening now' : 'Already happened'),
      ('What happened', _d.incident?.label ?? ''),
      ('Route or corridor', _or(_d.route)),
      ('Number plate or matatu name', _or(_d.vehicle.toUpperCase())),
      ('SACCO or operator', _or(_d.sacco)),
      ('Where it happened', _or(_d.area)),
      ('What would help most', _d.support?.title ?? ''),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        actions: [QuickExitButton(controller: _c)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Step 3 of 3', style: text.labelLarge),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text('Review your details', style: text.headlineMedium),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nothing has been sent yet. Tap Submit report to send this '
                  'to SafeSignal. SafeSignal is not an emergency service.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: SafeSignalColors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (label, value) in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Semantics(
                              container: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label, style: text.labelLarge),
                                  const SizedBox(height: 2),
                                  Text(
                                    value,
                                    style: text.bodyLarge?.copyWith(
                                      color: SafeSignalColors.oceanDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_message(_c.state) case final msg?) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SafeSignalColors.coralSubtle,
                        border: Border.all(color: SafeSignalColors.coral),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg,
                        style: text.bodyMedium?.copyWith(
                          color: SafeSignalColors.oceanDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                if (submitting) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    label: 'Submitting your report',
                    child: const LinearProgressIndicator(),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: submitting ? null : _c.submit,
                  child: Text(submitting ? 'Submitting…' : 'Submit report'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Edit details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _or(String v) => v.trim().isEmpty ? 'Not provided' : v.trim();

  /// Wording for every non-success outcome. The report stays on screen for a retry.
  static String? _message(SubmissionState s) => switch (s) {
        ValidationFailed() =>
          'The server could not accept some details. Tap Edit details to '
              'check them, then try again.',
        NetworkFailed(timedOut: true) =>
          'The server took too long to respond. Your report may or may not '
              'have arrived. You can tap Submit report again: retrying the '
              'same report will not create a duplicate while the server '
              'keeps running.',
        NetworkFailed() =>
          'Could not reach SafeSignal. Check your connection and tap Submit '
              'report to try again. Your details are still here.',
        RateLimited(:final retryAfterSeconds) =>
          'Too many reports from this connection. Please wait '
              '${_wait(retryAfterSeconds)} and try again.',
        UnexpectedResponse() =>
          'Something went wrong on the server. Your report was not '
              'confirmed. Please try again later.',
        NotConfigured() =>
          'This build of the app is not connected to a SafeSignal server, '
              'so nothing was sent.',
        _ => null,
      };

  static String _wait(int? seconds) {
    if (seconds == null || seconds <= 0) return 'a while';
    if (seconds < 90) return '$seconds seconds';
    return '${(seconds / 60).ceil()} minutes';
  }
}
