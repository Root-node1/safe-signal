import 'package:flutter/material.dart';

import '../theme.dart';

/// Branded placeholder. Reporting is not built yet, and nothing here talks to a server.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                    'Welcome to SafeSignal',
                    style: text.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A way for matatu and boda-boda commuters in Kenya to '
                  'report safety incidents.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SafeSignalColors.amberSubtle,
                    border: Border.all(color: SafeSignalColors.amber),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coming soon',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: SafeSignalColors.amberDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Incident reporting is not available in the app yet. '
                        'This version is an early foundation only.',
                        style: text.bodyMedium?.copyWith(
                          color: SafeSignalColors.oceanDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  // Intentionally disabled until reporting is built.
                  onPressed: null,
                  child: const Text('Report an incident (coming soon)'),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SafeSignalColors.coralSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'SafeSignal is not an emergency service and does not '
                    'monitor routes or verify reports. If you are in '
                    'immediate danger, call 999 or 112.',
                    style: text.bodyMedium?.copyWith(
                      color: SafeSignalColors.oceanDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
