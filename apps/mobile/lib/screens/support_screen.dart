import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/quick_exit_button.dart';
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
    final text = Theme.of(context).textTheme;
    final l = context.l10n;

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
              padding: const EdgeInsets.all(24),
              children: [
                Text(l.stepOf(2, 3), style: text.labelLarge),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(l.supportHeading, style: text.headlineMedium),
                ),
                const SizedBox(height: 8),
                Text(l.supportIntro, style: text.bodyLarge),
                const SizedBox(height: 16),
                for (final option in SupportOption.values)
                  _OptionTile(
                    option: option,
                    selected: _d.support == option,
                    onTap: option.available
                        ? () => setState(() {
                              _d.support = option;
                              _showError = false;
                            })
                        : null,
                  ),
                if (_showError)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l.chooseSupportError,
                      style: text.bodyMedium?.copyWith(
                        color: SafeSignalColors.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _continue, child: Text(l.actionReview)),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SupportOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        enabled: enabled,
        button: true,
        label: '${l.supportTitle(option)}. ${l.supportHint(option)}'
            '${enabled ? '' : ' ${l.unavailableSemantics}'}',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected
              ? SafeSignalColors.tealSubtle
              : enabled
                  ? Colors.white
                  : SafeSignalColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? SafeSignalColors.teal : SafeSignalColors.border,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? SafeSignalColors.teal
                          : SafeSignalColors.border,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.supportTitle(option), style: text.titleMedium),
                          const SizedBox(height: 2),
                          Text(l.supportHint(option), style: text.bodyMedium),
                          if (!enabled) ...[
                            const SizedBox(height: 4),
                            Text(
                              l.unavailableTag,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: SafeSignalColors.amberDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
