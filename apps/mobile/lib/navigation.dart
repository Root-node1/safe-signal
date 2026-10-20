import 'package:flutter/material.dart';

/// Standard route, or an instant one when the user has turned animations off.
Route<T> appRoute<T>(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.of(context).disableAnimations) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, _, _) => builder(ctx),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
  return MaterialPageRoute<T>(builder: builder);
}
