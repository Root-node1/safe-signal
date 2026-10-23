import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../design_tokens.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../storage/pending_draft_store.dart';
import '../widgets/widgets.dart';
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

  /// Whether a manual discard operation is in progress. Prevents double-taps
  /// while the deletion is happening (FR-3.3, RR-4.3).
  bool _isDiscarding = false;

  /// Whether the last discard attempt failed. The record is still on the
  /// device and an error banner is shown (FR-3.3).
  bool _discardFailed = false;

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

  /// Confirms and performs a manual discard of the pending report, then returns
  /// to the start of the reporting flow (FR-3.2). On failure the record is
  /// retained and an error banner is shown (FR-3.3, RR-4.3).
  Future<void> _onDiscard() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDiscardConfirmation(context);
    if (!mounted || !confirmed) return;

    setState(() {
      _isDiscarding = true;
      _discardFailed = false;
    });

    try {
      await _c.discardPending();
      if (!mounted) return;
      // Discard clears the draft and key and returns to the start of the flow.
      navigator.popUntil((r) => r.isFirst);
    } on PendingDraftDeleteFailed {
      if (mounted) {
        setState(() {
          _isDiscarding = false;
          _discardFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
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
    // The secondary action mirrors the height of the primary one, which the
    // shared theme defines, rather than repeating a literal in this screen.
    final secondaryButtonHeight =
        Theme.of(context).filledButtonTheme.style?.minimumSize?.resolve({})?.height ??
            kTouchMin;

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
              padding: const EdgeInsets.all(kSpace6),
              children: [
                StepHeader(
                  stepLabel: l.stepOf(3, 3),
                  title: l.reviewTitle,
                  subtitle: l.reviewIntro,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(kRadiusLg),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(kSpace4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == rows.length - 1 ? 0 : kSpace3,
                            ),
                            child: Semantics(
                              container: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // labelLarge is the teal row key in the
                                  // shared theme; the value sits under it.
                                  Text(rows[i].$1, style: text.labelLarge),
                                  const SizedBox(height: kSpace1),
                                  Text(
                                    rows[i].$2,
                                    style: text.bodyLarge?.copyWith(
                                      color: scheme.onSurface,
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
                 if (_c.reportWasEdited) ...[
                    const SizedBox(height: kSpace4),
                    SafeSignalBanner(
                      variant: SafeSignalBannerVariant.notice,
                      title: '',
                      body: l.restoredEditedNotice,
                    ),
                  ],
                 if (_message(l) case final msg?) ...[
                    const SizedBox(height: kSpace4),
                    // The error variant is a live region, so TalkBack announces
                    // the message as soon as it appears.
                    SafeSignalBanner(
                      variant: SafeSignalBannerVariant.error,
                      title: '',
                      body: msg,
                    ),
                  ],
                 // Discard failure banner (T-17). The record was not deleted;
                 // the app does not claim success (FR-3.3, RR-4.3).
                 if (_discardFailed) ...[
                   const SizedBox(height: kSpace4),
                   SafeSignalBanner(
                     variant: SafeSignalBannerVariant.error,
                     title: l.discardFailedTitle,
                     body: l.discardFailedBody,
                   ),
                 ],
                if (submitting) ...[
                  const SizedBox(height: kSpace4),
                  Semantics(
                    liveRegion: true,
                    label: l.submittingSemantics,
                    child: const LinearProgressIndicator(),
                  ),
                ],
                const SizedBox(height: kSpace6),
                FilledButton(
                  onPressed: submitting ? null : _c.submit,
                  child: Text(submitting ? l.submitting : l.actionSubmit),
                ),
                 const SizedBox(height: kSpace2),
                 OutlinedButton(
                   style: OutlinedButton.styleFrom(
                     minimumSize: Size.fromHeight(secondaryButtonHeight),
                   ),
                   onPressed: submitting ? null : () => Navigator.of(context).pop(),
                   child: Text(l.actionEdit),
                 ),
                 // Discard saved report — only when a pending report exists.
                 // Visually subordinate to Submit: a TextButton in the theme's
                 // error colour (coral), not a FilledButton (T-17, FR-3.1).
                 if (_c.pendingOutcome is PendingDraftAvailable) ...[
                   const SizedBox(height: kSpace2),
                   SizedBox(
                     width: double.infinity,
                     child: TextButton(
                       style: TextButton.styleFrom(
                         minimumSize: Size.fromHeight(kTouchMin),
                         foregroundColor: scheme.error,
                       ),
                       onPressed:
                           _isDiscarding ? null : () => _onDiscard(),
                       child: _isDiscarding
                           ? const SizedBox.square(
                               child: CircularProgressIndicator(strokeWidth: 2),
                             )
                           : Text(l.discardAction),
                     ),
                   ),
                 ],
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
  String? _message(AppLocalizations l) => switch (_c.state) {
        ValidationFailed() => l.errValidation,
        NetworkFailed() when _c.pendingMatchesAttempt =>
          l.errUnknownOutcome,
        NetworkFailed(timedOut: true) => l.errTimeout,
        NetworkFailed() => l.errOffline,
        RateLimited(:final retryAfterSeconds) =>
          l.errRateLimited(_wait(l, retryAfterSeconds)),
        UnexpectedResponse(keyConflict: true)
        when _c.pendingOutcome is PendingDraftAvailable =>
          l.errKeyConflict,
        UnexpectedResponse() => l.errUnexpected,
        NotConfigured() => l.errNotConfigured,
        _ => null,
      };

  String _wait(AppLocalizations l, int? seconds) {
    if (seconds == null || seconds <= 0) return l.waitAWhile;
    if (seconds < 90) return l.waitSeconds(seconds);
    return l.waitMinutes((seconds / 60).ceil());
  }
}
