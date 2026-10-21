import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// The standardised heading block placed at the top of every reporting step.
///
/// Renders a step-counter label, a screen heading, and an optional subtitle
/// paragraph — all drawn from the shared [TextTheme] so they respond correctly
/// to both light and dark mode and to system text-scale preferences.
///
/// Accessibility:
///   - The heading [Text] is wrapped in [Semantics(header: true)] so TalkBack
///     announces it as a heading, allowing swipe-by-heading navigation.
///   - The [stepLabel] is read as ordinary body text before the heading.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.stepLabel,
    required this.title,
    this.subtitle,
  });

  /// Short progress string, e.g. "Step 1 of 3". Rendered with labelLarge.
  final String stepLabel;

  /// Screen heading. Rendered with headlineMedium and marked as a heading
  /// for assistive technology.
  final String title;

  /// Optional supporting paragraph. Rendered with bodyLarge.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(stepLabel, style: text.labelLarge),
        const SizedBox(height: kSpace2),
        // header: true lets TalkBack users navigate by headings.
        Semantics(
          header: true,
          child: Text(title, style: text.headlineMedium),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: kSpace2),
          Text(subtitle!, style: text.bodyLarge),
        ],
        const SizedBox(height: kSpace4),
      ],
    );
  }
}
