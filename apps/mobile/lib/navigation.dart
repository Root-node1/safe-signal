import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Standard route, or an instant one when the user has turned animations off.
///
/// The animated path fades the next screen in while sliding it up slightly
/// (0.03 of the page height), using the shared motion tokens: [kDurationSlow]
/// forwards and [kDurationBase] backwards.
///
/// When [MediaQuery.disableAnimations] is set — Android "Remove animations" in
/// Developer Options, or an assistive-technology preference — the route is
/// instant, so nothing moves for people who asked for that.
///
/// The transition only fades and slides the page it is given.  It never
/// reveals report content on its own: the destination screen decides what is
/// shown, and the same rules apply to the whole page.
Route<T> appRoute<T>(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.of(context).disableAnimations) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, _, _) => builder(ctx),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
  return PageRouteBuilder<T>(
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
    transitionDuration: kDurationSlow,
    reverseTransitionDuration: kDurationBase,
  );
}
