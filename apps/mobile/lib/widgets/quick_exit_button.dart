import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/submission_controller.dart';

/// Clears the in-memory draft and submission state, returns to a blank home screen, then asks Android to close the app.
///
/// Limits: this cannot erase Android's recent-apps preview, screenshots, keyboard history,
/// backups or anything else outside the app. It only discards what SafeSignal holds in memory.
void quickExit(BuildContext context, SubmissionController controller) {
  controller.reset();
  Navigator.of(context).popUntil((r) => r.isFirst);
  SystemNavigator.pop();
}

class QuickExitButton extends StatelessWidget {
  const QuickExitButton({super.key, required this.controller});

  final SubmissionController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: 'Quick exit. Clears this report and closes SafeSignal.',
        excludeSemantics: true,
        onTap: () => quickExit(context, controller),
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFC24136),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () => quickExit(context, controller),
          child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
