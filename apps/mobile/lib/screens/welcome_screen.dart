import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../theme.dart';
import 'report_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.controller});

  final SubmissionController controller;
  ReportDraft get draft => controller.draft;

  void _start(BuildContext context, Timing timing) {
    draft.timing = timing;
    Navigator.of(context).push(
      appRoute<void>(context, (_) => ReportScreen(controller: controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
              padding: const EdgeInsets.all(24),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Report an incident',
                    style: text.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SafeSignal helps matatu and boda-boda commuters in Kenya '
                  'write down a safety incident. No account is needed, and '
                  'every detail except what happened is optional.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _start(context, Timing.after),
                  child: const Text('Report an incident'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: SafeSignalColors.coral,
                  ),
                  onPressed: () => _start(context, Timing.now),
                  child: const Text('Report what is happening now'),
                ),
                const SizedBox(height: 24),
                _Notice(
                  background: SafeSignalColors.amberSubtle,
                  border: SafeSignalColors.amber,
                  title: 'Early prototype',
                  titleColor: SafeSignalColors.amberDark,
                  body: 'Your report is sent to SafeSignal only when you tap '
                      'Submit on the last step, and nothing is saved on your '
                      'phone. In this prototype, reports are stored '
                      'temporarily and may be cleared.',
                ),
                const SizedBox(height: 16),
                const _Notice(
                  background: SafeSignalColors.coralSubtle,
                  title: 'Not an emergency service',
                  titleColor: SafeSignalColors.coral,
                  body: 'SafeSignal does not contact police or anyone else, '
                      'and does not monitor routes or verify reports. If you '
                      'are in immediate danger, call 999 or 112.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.background,
    this.border,
    required this.title,
    required this.titleColor,
    required this.body,
  });

  final Color background;
  final Color? border;
  final String title;
  final Color titleColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: border == null ? null : Border.all(color: border!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: SafeSignalColors.oceanDark),
          ),
        ],
      ),
    );
  }
}
