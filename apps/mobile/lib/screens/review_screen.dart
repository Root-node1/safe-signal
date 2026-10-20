import 'package:flutter/material.dart';

import '../models/report_draft.dart';
import '../widgets/quick_exit_button.dart';
import '../navigation.dart';
import '../theme.dart';
import 'confirmation_screen.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.draft});

  final ReportDraft draft;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = <(String, String)>[
      ('When', draft.timing == Timing.now ? 'Happening now' : 'Already happened'),
      ('What happened', draft.incident?.label ?? ''),
      ('Route or corridor', _or(draft.route)),
      ('Number plate or matatu name', _or(draft.vehicle.toUpperCase())),
      ('SACCO or operator', _or(draft.sacco)),
      ('Where it happened', _or(draft.area)),
      ('What would help most', draft.support?.title ?? ''),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        actions: [QuickExitButton(draft: draft)],
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
                  'Nothing has been sent. This version of the app cannot send '
                  'reports yet.',
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    appRoute<void>(context, (_) => ConfirmationScreen(draft: draft)),
                  ),
                  child: const Text('Finish'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
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
}
