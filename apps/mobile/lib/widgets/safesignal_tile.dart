import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../theme.dart';

/// A selectable radio-style tile used for incident categories and support
/// options throughout the reporting flow.
///
/// Accessibility (WCAG 2.5.5 / TalkBack):
///   - Minimum height: [kTouchMin] (48 dp).
///   - [Semantics] marks items as mutually exclusive radio buttons so TalkBack
///     announces "Selected" / "Not selected" with the group context.
///   - Disabled tiles announce their unavailability via [enabled] = false.
///   - [semanticLabel] overrides the computed label when callers need a richer
///     announcement (e.g. title + description combined).
///
/// Animation:
///   - Background and border transition via [AnimatedContainer] at
///     [kDurationBase].  The animation is skipped when
///     [MediaQuery.disableAnimations] is true (Android "Remove animations"
///     Developer Option, or assistive-technology preference).
class SafeSignalTile extends StatelessWidget {
  const SafeSignalTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.badge,
    required this.selected,
    this.enabled = true,
    required this.onTap,
    this.semanticLabel,
  });

  /// Optional widget shown before the text content (e.g. an icon).
  final Widget? leading;

  /// Primary label. Rendered with [TextTheme.titleMedium].
  final String title;

  /// Optional secondary line. Rendered with [TextTheme.bodyMedium].
  final String? subtitle;

  /// Optional badge text shown below the subtitle (e.g. "Unavailable · In development").
  /// Rendered with [TextTheme.labelSmall] in an amber-dark colour.
  final String? badge;

  /// Whether this tile is in the selected state.
  final bool selected;

  /// Whether the tile is interactive. Disabled tiles are visually dimmed and
  /// not tappable; [onTap] is ignored when false.
  final bool enabled;

  /// Called when the tile is tapped. Pass null to make the tile permanently
  /// non-interactive (equivalent to [enabled] = false).
  final VoidCallback? onTap;

  /// Overrides the accessibility label read by TalkBack. When omitted, the
  /// label is built from [title] and [subtitle].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final noAnim = MediaQuery.of(context).disableAnimations;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve colours for each state from the theme.
    final Color bgColor;
    final Color borderColor;
    final double borderWidth;

    if (selected) {
      bgColor     = isDark ? SafeSignalColors.darkTealSubtle : SafeSignalColors.tealSubtle;
      borderColor = scheme.primary;
      borderWidth = 2.5;
    } else if (!enabled) {
      bgColor     = scheme.surface.withAlpha(isDark ? 180 : 255);
      borderColor = scheme.outlineVariant;
      borderWidth = 1.0;
    } else {
      bgColor     = scheme.surface;
      borderColor = scheme.outlineVariant;
      borderWidth = 1.0;
    }

    // The label TalkBack will announce for the whole tile.
    final String computedLabel = semanticLabel ??
        [title, ?subtitle].join('. ');

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpace2),
      child: Semantics(
        // Marks this as a radio button inside a mutually exclusive group.
        inMutuallyExclusiveGroup: true,
        checked: selected,
        enabled: enabled,
        button: true,
        label: computedLabel,
        // excludeSemantics prevents Flutter from also reading the child Text
        // widgets separately, which would double-announce content.
        excludeSemantics: true,
        onTap: (enabled && onTap != null) ? onTap : null,
        child: AnimatedContainer(
          duration: noAnim ? Duration.zero : kDurationBase,
          curve: Curves.easeInOut,
          constraints: BoxConstraints(minHeight: kTouchMin),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(kRadiusLg),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Material(
            // Transparent so AnimatedContainer's color shows through.
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(kRadiusLg),
              onTap: (enabled && onTap != null) ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpace4,
                  vertical: kSpace3,
                ),
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: kSpace3),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title, style: text.titleMedium),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(subtitle!, style: text.bodyMedium),
                            ],
                            if (badge != null) ...[
                              const SizedBox(height: kSpace1),
                              Text(
                                badge!,
                                style: text.labelSmall?.copyWith(
                                  color: isDark
                                      ? SafeSignalColors.darkAmberDark
                                      : SafeSignalColors.amberDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Selected indicator: filled radio dot using the primary colour.
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? scheme.primary : scheme.outline,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
