import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../theme.dart';
import 'report_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.controller,
    required this.onLocaleChanged,
  });

  final SubmissionController controller;
  final ValueChanged<Locale> onLocaleChanged;
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
    final l = context.l10n;
    final code = Localizations.localeOf(context).languageCode;

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
                  container: true,
                  label: l.language,
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
                      ButtonSegment(value: 'sw', label: Text(l.languageSwahili)),
                    ],
                    selected: {code == 'sw' ? 'sw' : 'en'},
                    onSelectionChanged: (s) => onLocaleChanged(Locale(s.first)),
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    l.homeTitle,
                    style: text.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.homeIntro, style: text.bodyLarge),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _start(context, Timing.after),
                  child: Text(l.homeReport),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: SafeSignalColors.coral,
                  ),
                  onPressed: () => _start(context, Timing.now),
                  child: Text(l.homeReportNow),
                ),
                const SizedBox(height: 24),
                _Notice(
                  background: SafeSignalColors.amberSubtle,
                  border: SafeSignalColors.amber,
                  title: l.prototypeTitle,
                  titleColor: SafeSignalColors.amberDark,
                  body: l.prototypeBody,
                ),
                const SizedBox(height: 16),
                _Notice(
                  background: SafeSignalColors.coralSubtle,
                  title: l.notEmergencyTitle,
                  titleColor: SafeSignalColors.coral,
                  body: l.notEmergencyBody,
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
