import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/submission_controller.dart';
import '../l10n/l10n.dart';

/// Clears navigation and asks the platform to close the app.
///
/// Used by [QuickExitButton] after [SubmissionController.prepareForQuickExit]
/// has already cleared the in-memory draft and key. Does not call
/// [SubmissionController.reset] — that is redundant with the prepare step.
void quickExit(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  SystemNavigator.pop().catchError((_) {});
}

class QuickExitButton extends StatefulWidget {
  const QuickExitButton({super.key, required this.controller});

  final SubmissionController controller;

  @override
  State<QuickExitButton> createState() => _QuickExitButtonState();
}

class _QuickExitButtonState extends State<QuickExitButton> {
  bool _inProgress = false;

  Future<void> _handleExit() async {
    if (_inProgress) return;
    setState(() => _inProgress = true);

    final status = await widget.controller.prepareForQuickExit();
    if (!mounted) return;

    if (status == QuickExitDeletionStatus.success) {
      quickExit(context);
      return;
    }

    // Deletion failed — the record is still on the device. Show a dialog
    // that lets the user retry or exit anyway (FR-11.2, RR-4.3).
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.quickExitRecordRetainedTitle),
        content: Text(context.l10n.quickExitRecordRetainedBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              quickExit(context);
            },
            child: Text(context.l10n.quickExitExitAnyway),
          ),
          FilledButton(
            onPressed: () async {
              final retry =
                  await widget.controller.retryQuickExitDeletion();
              if (!mounted) return;
              if (retry == QuickExitDeletionStatus.success) {
                Navigator.of(context).pop();
                quickExit(context);
              }
            },
            child: Text(context.l10n.quickExitTryAgain),
          ),
        ],
      ),
    );

    if (mounted) setState(() => _inProgress = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _inProgress;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: context.l10n.quickExitSemantics,
        excludeSemantics: true,
        onTap: busy ? null : _handleExit,
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFC24136),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: busy ? null : _handleExit,
          child: Text(context.l10n.quickExitLabel,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
