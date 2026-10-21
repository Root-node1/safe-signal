import 'package:flutter/material.dart';

import '../api/submission_controller.dart';
import '../design_tokens.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
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
              padding: const EdgeInsets.all(kSpace6),
              children: [
                Semantics(
                  container: true,
                  label: l.language,
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(0, kTouchMin),
                    ),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
                      ButtonSegment(value: 'sw', label: Text(l.languageSwahili)),
                    ],
                    selected: {code == 'sw' ? 'sw' : 'en'},
                    onSelectionChanged: (s) => onLocaleChanged(Locale(s.first)),
                  ),
                ),
                const SizedBox(height: kSpace5),
                Semantics(
                  header: true,
                  child: Text(
                    l.homeTitle,
                    style: text.headlineMedium,
                  ),
                ),
                const SizedBox(height: kSpace3),
                Text(l.homeIntro, style: text.bodyLarge),
                const SizedBox(height: kSpace6),
                FilledButton(
                  onPressed: () => _start(context, Timing.after),
                  child: Text(l.homeReport),
                ),
                const SizedBox(height: kSpace2),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(kTouchMin),
                    foregroundColor: SafeSignalColors.coral,
                  ),
                  onPressed: () => _start(context, Timing.now),
                  child: Text(l.homeReportNow),
                ),
                const SizedBox(height: kSpace6),
                SafeSignalBanner(
                  variant: SafeSignalBannerVariant.notice,
                  title: l.prototypeTitle,
                  body: l.prototypeBody,
                ),
                const SizedBox(height: kSpace4),
                SafeSignalBanner(
                  variant: SafeSignalBannerVariant.warning,
                  title: l.notEmergencyTitle,
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
