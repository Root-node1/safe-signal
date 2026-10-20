import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/submission_controller.dart';
import '../models/report_draft.dart';
import '../theme.dart';
import '../widgets/quick_exit_button.dart';

/// Shown only after the server confirmed the report with a reference code.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.controller});

  final SubmissionController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = controller.state;
    final code = state is Succeeded ? state.code : '';
    final showHelplines = state is Succeeded && state.support == SupportOption.support;

    return PopScope(
      // Android Back behaves like Done: the draft is already gone, so never return to Review.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.reset();
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        automaticallyImplyLeading: false,
        actions: [QuickExitButton(controller: controller)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Semantics(
                  header: true,
                  child: Text('Report received', style: text.headlineMedium),
                ),
                const SizedBox(height: 12),
                Text(
                  'The SafeSignal server accepted your report. In this '
                  'prototype, reports are stored temporarily and may be '
                  'cleared.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: SafeSignalColors.teal, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reference code', style: text.labelLarge),
                      const SizedBox(height: 4),
                      SelectableText(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: SafeSignalColors.oceanDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                        child: const Text('Copy code'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You cannot look this code up yet, and it may stop '
                        'being valid.',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SafeSignalColors.amberSubtle,
                    border: Border.all(color: SafeSignalColors.amber),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Nobody has been contacted. This report has not been '
                    'verified, reviewed, or forwarded, and nothing is saved '
                    'on your phone. SafeSignal is not an emergency service. '
                    'If you are in immediate danger, call 999 or 112.',
                    style: text.bodyMedium?.copyWith(
                      color: SafeSignalColors.oceanDark,
                    ),
                  ),
                ),
                if (showHelplines) ...[
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text('Emergency and support numbers',
                        style: text.titleMedium),
                  ),
                  const SizedBox(height: 4),
                  Text('Call these yourself. SafeSignal does not make calls.',
                      style: text.bodyMedium),
                  const SizedBox(height: 8),
                  for (final r in supportResources)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        title: Text(r.name, style: text.titleMedium),
                        subtitle: Text(r.detail),
                        trailing: Text(
                          r.tel,
                          style: text.headlineMedium?.copyWith(fontSize: 24),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    controller.reset();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
