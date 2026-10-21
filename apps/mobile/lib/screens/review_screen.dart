import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../l10n/l10n.dart';
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
    final l = context.l10n;
    final submitting = _c.isSubmitting;
    final rows = <(String, String)>[
      (l.reviewRowWhen, l.timingLabel(_d.timing)),
      (l.reviewRowWhat, _d.incident == null ? '' : l.incidentLabel(_d.incident!)),
      (l.fieldRoute, _or(l, _d.route)),
      (l.fieldVehicle, _or(l, _d.vehicle.toUpperCase())),
      (l.fieldSacco, _or(l, _d.sacco)),
      (l.fieldArea, _or(l, _d.area)),
      (l.reviewRowSupport, _d.support == null ? '' : l.supportTitle(_d.support!)),
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
                Text(l.stepOf(3, 3), style: text.labelLarge),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(l.reviewTitle, style: text.headlineMedium),
                ),
                const SizedBox(height: 8),
                Text(l.reviewIntro, style: text.bodyLarge),
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
                if (_message(l, _c.state) case final msg?) ...[
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
                    label: l.submittingSemantics,
                    child: const LinearProgressIndicator(),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: submitting ? null : _c.submit,
                  child: Text(submitting ? l.submitting : l.actionSubmit),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: submitting ? null : () => Navigator.of(context).pop(),
                  child: Text(l.actionEdit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _or(AppLocalizations l, String v) =>
      v.trim().isEmpty ? l.notProvided : v.trim();

  /// Wording for every non-success outcome. The report stays on screen for a retry.
  static String? _message(AppLocalizations l, SubmissionState s) => switch (s) {
        ValidationFailed() => l.errValidation,
        NetworkFailed(timedOut: true) => l.errTimeout,
        NetworkFailed() => l.errOffline,
        RateLimited(:final retryAfterSeconds) =>
          l.errRateLimited(_wait(l, retryAfterSeconds)),
        UnexpectedResponse() => l.errUnexpected,
        NotConfigured() => l.errNotConfigured,
        _ => null,
      };

  static String _wait(AppLocalizations l, int? seconds) {
    if (seconds == null || seconds <= 0) return l.waitAWhile;
    if (seconds < 90) return l.waitSeconds(seconds);
    return l.waitMinutes((seconds / 60).ceil());
  }
}
