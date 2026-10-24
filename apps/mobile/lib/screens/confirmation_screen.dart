import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/submission_controller.dart';
import '../design_tokens.dart';
import '../l10n/l10n.dart';
import '../models/report_draft.dart';
import '../widgets/widgets.dart';

/// Shown only after the server confirmed the report with a reference code.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.controller});

  final SubmissionController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final l = context.l10n;
        final state = controller.state;
        final String code = switch (state) {
          Succeeded(:final code) || SucceededButRecordRetained(:final code) =>
            code,
          _ => '',
        };
        final bool showHelplines = switch (state) {
          Succeeded(:final support) ||
          SucceededButRecordRetained(:final support) =>
            support == SupportOption.support,
          _ => false,
        };
        final bool recordRetained = state is SucceededButRecordRetained;

        return PopScope(
          // Android Back behaves like Done: the draft is already gone, so never return to Review.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              controller.reset();
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('SafeSignal'),
              automaticallyImplyLeading: false,
              actions: [QuickExitButton(controller: controller)],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.all(kSpace6),
                    children: [
                      Semantics(
                        header: true,
                        child:
                            Text(l.confirmTitle, style: text.headlineMedium),
                      ),
                      const SizedBox(height: kSpace3),
                      Text(l.confirmBody, style: text.bodyLarge),
                      const SizedBox(height: kSpace6),
                      Card(
                        elevation: 0,
                        color: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusLg),
                          side: BorderSide(color: scheme.primary, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(kSpace4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.refCode, style: text.labelLarge),
                              const SizedBox(height: kSpace1),
                              SelectableText(
                                code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: kSpace2),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize:
                                      const Size(kTouchMin, kTouchMin),
                                ),
                                onPressed: () => Clipboard.setData(
                                    ClipboardData(text: code)),
                                child: Text(l.copyCode),
                              ),
                              const SizedBox(height: kSpace2),
                              Text(l.codeNote, style: text.bodyMedium),
                              const SizedBox(height: kSpace2),
                              Text(l.screenshotNote, style: text.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      if (recordRetained) ...[
                        const SizedBox(height: kSpace6),
                        SafeSignalBanner(
                          variant: SafeSignalBannerVariant.error,
                          title: l.recordRetainedTitle,
                          body: l.recordRetainedBody,
                        ),
                        const SizedBox(height: kSpace4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(kTouchMin, kTouchMin),
                          ),
                          onPressed: () async {
                            final ok =
                                await controller.retryPendingDeletion();
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.recordStillRetained)),
                              );
                            }
                          },
                          child: Text(l.deleteSavedReport),
                        ),
                      ],
                      const SizedBox(height: kSpace6),
                      // A notice, not a live region: it states what has not happened
                      // yet, and must not interrupt TalkBack on arrival.
                      SafeSignalBanner(
                        variant: SafeSignalBannerVariant.notice,
                        title: '',
                        body: l.confirmNotice,
                      ),
                      if (showHelplines) ...[
                        const SizedBox(height: kSpace6),
                        Semantics(
                          header: true,
                          child: Text(l.helplinesTitle,
                              style: text.titleMedium),
                        ),
                        const SizedBox(height: kSpace1),
                        Text(l.helplinesIntro, style: text.bodyMedium),
                        const SizedBox(height: kSpace2),
                        for (var i = 0; i < Helpline.values.length; i++) ...[
                          if (i > 0) const SizedBox(height: kSpace2),
                          _helplineCard(context, l, Helpline.values[i]),
                        ],
                      ],
                      const SizedBox(height: kSpace6),
                      FilledButton(
                        onPressed: () {
                          controller.reset();
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: Text(l.actionDone),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// One helpline row: the name, what it is for, and the number to dial.
  Widget _helplineCard(BuildContext context, AppLocalizations l, Helpline h) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpace4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.helplineName(h), style: text.titleMedium),
          subtitle: Text(l.helplineDetail(h)),
          trailing: Text(
            h.tel,
            style: text.headlineMedium?.copyWith(
              fontSize: 24,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
