import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../design_tokens.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../widgets/widgets.dart';
import 'review_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, required this.controller});

  final SubmissionController controller;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _showError = false;

  ReportDraft get _d => widget.controller.draft;

  void _continue() {
    if (_d.support == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).push(
      appRoute<void>(context, (_) => ReviewScreen(controller: widget.controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // The secondary action mirrors the height of the primary one, which the
    // shared theme defines, rather than repeating a literal in this screen.
    final secondaryButtonHeight =
        Theme.of(context).filledButtonTheme.style?.minimumSize?.resolve({})?.height ??
            kTouchMin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSignal'),
        actions: [QuickExitButton(controller: widget.controller)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(kSpace6),
              children: [
                StepHeader(
                  stepLabel: l.stepOf(2, 3),
                  title: l.supportHeading,
                  subtitle: l.supportIntro,
                ),
                for (final option in SupportOption.values)
                  SafeSignalTile(
                    title: l.supportTitle(option),
                    subtitle: l.supportHint(option),
                    badge: option.available ? null : l.unavailableTag,
                    selected: _d.support == option,
                    enabled: option.available,
                    // Disabled tiles are dimmed and their badge is not part of
                    // the merged label, so the unavailability is spelled out
                    // here for TalkBack.
                    semanticLabel: option.available
                        ? null
                        : '${l.supportTitle(option)}. ${l.supportHint(option)} '
                            '${l.unavailableSemantics}',
                    onTap: option.available
                        ? () => setState(() {
                              _d.support = option;
                              _showError = false;
                            })
                        : null,
                  ),
                if (_showError) ...[
                  const SizedBox(height: kSpace2),
                  SafeSignalBanner(
                    variant: SafeSignalBannerVariant.error,
                    title: '',
                    body: l.chooseSupportError,
                  ),
                ],
                const SizedBox(height: kSpace6),
                FilledButton(
                  onPressed: _continue,
                  child: Text(l.actionReview),
                ),
                const SizedBox(height: kSpace2),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(secondaryButtonHeight),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.actionBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
