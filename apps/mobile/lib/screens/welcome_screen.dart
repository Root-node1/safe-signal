import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/submission_controller.dart';
import '../design_tokens.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../storage/pending_draft_store.dart';
import '../theme.dart';
import 'report_screen.dart';

import '../widgets/safesignal_banner.dart';

/// The user's choice in the restore prompt dialog.
enum RestoreChoice { restore, keepSaved }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.controller,
    required this.onLocaleChanged,
  });

  final SubmissionController controller;
  final ValueChanged<Locale> onLocaleChanged;

  /// The draft the user is currently editing, if any. Used by the report flow
  /// to pre-fill fields.
  ReportDraft get draft => controller.draft;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Whether the user has dismissed the restore prompt for this session.
  /// The record stays on the device (FR-2.4); only the prompt is hidden.
  bool _promptDismissed = false;

  /// Whether the restore dialog has been shown this session. Prevents
  /// re-scheduling the dialog across rebuilds before the first frame callback
  /// fires (AR-2.2).
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Whether the restore prompt should currently be shown.
  bool _shouldShowPrompt(PendingDraftReadOutcome? outcome) {
    final error = widget.controller.pendingReadError;
    return !_promptDismissed &&
        error == null &&
        outcome is PendingDraftAvailable;
  }

  String _getMainTitle(AppLocalizations l, PendingDraftReadOutcome? outcome) {
    if (_shouldShowPrompt(outcome)) {
      return l.restoreTitle;
    }
    return l.homeTitle;
  }

  String _getMainIntro(AppLocalizations l, PendingDraftReadOutcome? outcome) {
    if (_shouldShowPrompt(outcome)) {
      return '${l.restoreIntro} ${l.restoreHasNotBeenSubmitted}';
    }
    return l.homeIntro;
  }

  /// Builds an announcement banner for an expired, corrupt, or unavailable
  /// pending report. AR-4.1 requires each to be announced through a live
  /// region. Returns null when no banner is needed.
  Widget? _buildStatusBanner(
    BuildContext context,
    AppLocalizations l,
    PendingDraftReadOutcome? outcome,
  ) {
    final error = widget.controller.pendingReadError;

    if (error is PendingDraftCorrupt) {
      return Semantics(
        liveRegion: true,
        child: SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: l.restoreCorruptIntro,
          body: '',
        ),
      );
    }

    if (error is PendingDraftUnavailable) {
      return Semantics(
        liveRegion: true,
        child: SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: l.restoreUnavailableIntro,
          body: '',
        ),
      );
    }

    // A failed deletion of an expired or corrupt record (RR-4.3, T-16). The
    // record is still on the device but is not offered for restore; the user
    // is told plainly that the deletion failed.
    if (error is PendingDraftDeleteFailed) {
      return Semantics(
        liveRegion: true,
        child: SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: l.restoreDeleteFailedIntro,
          body: l.restoreDeleteFailedBody,
        ),
      );
    }

    if (outcome is PendingDraftExpired) {
      final date =
          DateFormat.yMMMd(l.localeName).format(outcome.createdAt);
      return Semantics(
        liveRegion: true,
        child: SafeSignalBanner(
          variant: SafeSignalBannerVariant.error,
          title: l.restoreExpiredIntro,
          body: l.restoreSavedAt(date),
        ),
      );
    }

    return null;
  }

  /// Shows the restore prompt as a modal [AlertDialog] so that it is announced
  /// as a dialog with an accessible name (AR-1.2) and keyboard/screen-reader focus
  /// moves into the dialog on open and returns on close (AR-2.2).
  ///
  /// An inline [Card] cannot provide dialog semantics reliably — `Semantics(label:
  /// ...)` alone does not create a dialog role — so [showDialog] with
  /// [AlertDialog] is used instead. Flutter's dialog route wraps the content in
  /// `Semantics(dialog: true)` and creates a [FocusScope] that traps focus within
  /// the dialog and restores it to the invoking control when the dialog closes.
  /// The dialog title is the accessible name (AR-1.2). No sensitive pending-report
  /// content is shown beyond the save timestamp (FR-2.5, FR-4.3).
  Future<void> _showRestoreDialog(
    BuildContext context,
    AppLocalizations l,
    PendingDraftAvailable outcome,
  ) async {
    final stored = outcome.draft;
    final date = DateFormat.yMMMd(l.localeName).format(
      DateTime.fromMillisecondsSinceEpoch(stored.createdAt),
    );

    // Capture the navigator before any async gap so the context-parameter is
    // not used across an await (use_build_context_synchronously).
    final navigator = Navigator.of(context);

    final result = await showDialog<RestoreChoice>(
      context: context,
      barrierDismissible: true,
      // AlertDialog sets Semantics(dialog: true) automatically, which TalkBack
      // and VoiceOver announce as "dialog" (AR-1.2). The title is the accessible
      // name.
      builder: (BuildContext dialogContext) => AlertDialog(
        // semanticLabel becomes the accessible name announced alongside the
        // dialog role (AR-1.2). AlertDialog wraps the body in Semantics(namesRoute:
        // true, label: semanticLabel, scopesRoute: true) and the Dialog widget
        // sets SemanticsRole.alertDialog.
        semanticLabel: l.restoreTitle,
        title: Text(l.restoreTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.restoreIntro} ${l.restoreHasNotBeenSubmitted}'),
            const SizedBox(height: kSpace2),
            Text(
              l.restoreSavedAt(date),
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          // "Keep saved": dismiss the dialog, preserve the record on the device
          // (FR-2.4). The record remains in storage for next time.
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(RestoreChoice.keepSaved),
            child: Text(l.keepSaved),
          ),
          // "Restore": the affirmative action. autofocus moves keyboard and
          // screen-reader focus into the dialog (AR-2.2).
          FilledButton(
            autofocus: true,
            onPressed: () =>
                Navigator.of(dialogContext).pop(RestoreChoice.restore),
            child: Text(l.restore),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == null || result == RestoreChoice.keepSaved) {
      // Dismissed by back, tap-outside, or "Keep saved": the record stays on
      // the device (FR-2.4).
      setState(() => _promptDismissed = true);
    } else if (result == RestoreChoice.restore) {
      final route = _reportRoute();
      final restoreOutcome = await widget.controller.restorePending();
      if (!mounted) return;
      if (restoreOutcome is RestoreSucceeded) {
        navigator.push(route);
      }
    }
  }

  Route<void> _reportRoute() =>
      appRoute<void>(context, _reportBuilder);

  Widget _reportBuilder(BuildContext context) =>
      ReportScreen(controller: widget.controller);

  void _start(BuildContext context, Timing timing) {
    final draft = widget.controller.draft;
    draft.timing = timing;
    Navigator.of(context).push(
      appRoute<void>(context, (_) => ReportScreen(controller: widget.controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.controller.pendingOutcome;
    final l = context.l10n;
    final code = Localizations.localeOf(context).languageCode;

    final showPrompt = _shouldShowPrompt(outcome);
    final available = showPrompt ? outcome as PendingDraftAvailable : null;
    final statusBanner = _buildStatusBanner(context, l, outcome);

    // Schedule the restore dialog once. showDialog is used instead of an inline
    // Card so the prompt has proper dialog semantics (AR-1.2) and focus moves
    // into and out of it (AR-2.2). The dialog is scheduled after the first frame
    // to avoid calling showDialog during build.
    if (showPrompt && !_hasShownDialog && available != null) {
      _hasShownDialog = true;
      final pending = available;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_promptDismissed) {
          _showRestoreDialog(context, l, pending);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SafeSignal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(kSpace6),
              children: [
                // Status banners (expired, corrupt, unavailable, delete failed).
                // AR-4.1: announced through a live region.
                if (statusBanner != null) ...[
                  statusBanner,
                  const SizedBox(height: kSpace4),
                ],
                // The restore prompt is shown as a modal dialog (see above),
                // not as an inline card, so it has dialog semantics and focus
                // management (AR-1.2, AR-2.2).
                Semantics(
                  container: true,
                  label: l.language,
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(0, kTouchMin),
                    ),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: 'en', label: Text(l.languageEnglish)),
                      ButtonSegment(
                          value: 'sw', label: Text(l.languageSwahili)),
                    ],
                    selected: {code == 'sw' ? 'sw' : 'en'},
                    onSelectionChanged: (s) =>
                        widget.onLocaleChanged(Locale(s.first)),
                  ),
                ),
                const SizedBox(height: kSpace5),
                Semantics(
                  header: true,
                  child: Text(
                    _getMainTitle(l, outcome),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: kSpace3),
                Text(
                  _getMainIntro(l, outcome),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: kSpace6),
                FilledButton(
                  onPressed: () => _start(context, Timing.after),
                  child: Text(l.homeReport),
                ),
                const SizedBox(height: kSpace2),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(kTouchMin),
                    foregroundColor: SafeSignalColors.coral,
                  ),
                  onPressed: () => _start(context, Timing.now),
                  child: Text(l.homeReportNow),
                ),
                const SizedBox(height: kSpace6),
                SafeSignalBanner(
                  variant: SafeSignalBannerVariant.notice,
                  title: l.prototypeTitle,
                  body: l.prototypeBody,
                ),
                const SizedBox(height: kSpace4),
                SafeSignalBanner(
                  variant: SafeSignalBannerVariant.warning,
                  title: l.notEmergencyTitle,
                  body: l.notEmergencyBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
