import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../theme.dart';

/// Severity of a [SafeSignalBanner].
///
/// Colour mapping (light / dark):
///   [notice]  — amber palette   (prototype notice, confirmation notice)
///   [warning] — coral palette, no border  (not-emergency, timing-now danger)
///   [error]   — coral palette with border, announced as a live region
///               (all submission error states)
enum SafeSignalBannerVariant { notice, warning, error }

/// A contextual inline banner for notices, warnings, and errors.
///
/// This widget replaces the private `_Notice` class in `WelcomeScreen`, the
/// `confirmNotice` container in `ConfirmationScreen`, and the inline error
/// containers in `ReviewScreen`.
///
/// Accessibility:
///   - [error] variant wraps the content in [Semantics(liveRegion: true)] so
///     TalkBack announces the message automatically when it appears on screen,
///     without the user navigating to it.  This preserves the behaviour of the
///     existing `Semantics(liveRegion: true)` containers it replaces.
///   - [notice] and [warning] variants do not announce automatically; they are
///     static informational content present on page load.
///   - If [title] is non-empty it is rendered in bold and read first.
class SafeSignalBanner extends StatelessWidget {
  const SafeSignalBanner({
    super.key,
    required this.variant,
    required this.title,
    required this.body,
    this.titleColor,
  });

  final SafeSignalBannerVariant variant;

  /// Bold heading text. Pass an empty string to show only the [body].
  final String title;

  /// Body paragraph.
  final String body;

  /// Override the title colour. When null a sensible default is derived from
  /// the [variant] and current brightness.
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    // Resolve colours from the token palette based on variant and brightness.
    final Color bg;
    final Color defaultTitleColor;
    final Color? borderColor;

    switch (variant) {
      case SafeSignalBannerVariant.notice:
        bg                = isDark ? SafeSignalColors.darkAmberSubtle : SafeSignalColors.amberSubtle;
        defaultTitleColor = isDark ? SafeSignalColors.darkAmberDark   : SafeSignalColors.amberDark;
        borderColor       = null;
      case SafeSignalBannerVariant.warning:
        bg                = isDark ? SafeSignalColors.darkCoralSubtle : SafeSignalColors.coralSubtle;
        defaultTitleColor = isDark ? SafeSignalColors.darkCoral       : SafeSignalColors.coral;
        borderColor       = null;
      case SafeSignalBannerVariant.error:
        bg                = isDark ? SafeSignalColors.darkCoralSubtle : SafeSignalColors.coralSubtle;
        defaultTitleColor = isDark ? SafeSignalColors.darkCoral       : SafeSignalColors.coral;
        borderColor       = isDark ? SafeSignalColors.darkCoral       : SafeSignalColors.coral;
    }

    final resolvedTitleColor = titleColor ?? defaultTitleColor;

    final Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpace4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: resolvedTitleColor,
              ),
            ),
            const SizedBox(height: kSpace1),
          ],
          Text(
            body,
            style: text.bodyMedium?.copyWith(
              // Body text uses the surface's onSurface colour for readability,
              // not the title accent colour.
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );

    // Error banners are live regions: TalkBack announces them when they appear.
    if (variant == SafeSignalBannerVariant.error) {
      return Semantics(liveRegion: true, child: content);
    }
    return content;
  }
}
