import 'package:flutter/material.dart';

/// Shared page transitions, so every screen change looks the same.
class AppNavigation {
  /// Builds a route that fades the new page in while sliding it up slightly.
  ///
  /// Input:  [page] — the screen to show.
  /// Output: a route to hand to `Navigator.push` / `pushReplacement`.
  ///
  /// A gentle fade suits the splash → onboarding → home sequence better than
  /// the default sideways slide, which would suggest the user can go back.
  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }
}
