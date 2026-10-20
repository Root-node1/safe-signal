import 'package:flutter/material.dart';

import '../models/report_draft.dart';
import '../widgets/quick_exit_button.dart';
import '../theme.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.draft});

  final ReportDraft draft;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        automaticallyImplyLeading: false,
        actions: [QuickExitButton(draft: draft)],
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
                  child: Text('Report not submitted', style: text.headlineMedium),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your report has not been submitted. This version of '
                  'SafeSignal cannot send reports, so no one has received '
                  'anything.',
                  style: text.bodyLarge,
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
                    'Nothing was saved on your phone. Your details are '
                    'cleared when you tap Done or close the app.',
                    style: text.bodyMedium?.copyWith(
                      color: SafeSignalColors.oceanDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SafeSignalColors.coralSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'SafeSignal is not an emergency service. If you are in '
                    'immediate danger, call 999 or 112.',
                    style: text.bodyMedium?.copyWith(
                      color: SafeSignalColors.oceanDark,
                    ),
                  ),
                ),
                if (draft.support == SupportOption.support) ...[
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
                    draft.clear();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text('Done'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
