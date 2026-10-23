import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Shows a confirmation dialog for discarding a saved pending report.
///
/// The dialog states clearly that the locally saved report will be deleted and
/// that the action cannot be undone. Returns `true` if the user confirms, `false`
/// if they cancel, use back, or tap the dimmed barrier — in every case that
/// returns `false` the report is preserved (FR-3.3, RR-4.3).
///
/// The destructive button uses the theme's error colour so it is visually
/// distinct but stays subordinate to a [FilledButton] primary action such as
/// Submit (T-17).
Future<bool> showDiscardConfirmation(
  BuildContext context,
) async {
  final l = context.l10n;
  return await showDialog<bool>(
        context: context,
        // barrierDismissible: true — the default. Barrier/back/cancel all
        // preserve the report (no deletion happens unless confirmed).
        builder: (BuildContext dialogContext) => AlertDialog(
          semanticLabel: l.discardConfirmTitle,
          title: Text(l.discardConfirmTitle),
          content: Text(l.discardConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.discardCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.discardConfirmDelete),
            ),
          ],
        ),
      ) ??
      false;
}
