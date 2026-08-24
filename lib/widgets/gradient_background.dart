import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// The dark blue-to-purple background used behind every screen.
///
/// Wrapping each screen in this widget keeps the app looking the same
/// everywhere and means the gradient is written down only once.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.child,
    super.key,
  });

  /// Mid-point colour of the gradient, between the dark background and purple.
  static const Color midnightBlue = Color(0xFF191D39);

  /// The screen content drawn on top of the gradient.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            midnightBlue,
            AppTheme.brandPurple,
          ],
          // The purple is held back until 58% down the screen so the top of
          // the page stays dark and the camera preview keeps good contrast.
          stops: [0.0, 0.58, 1.0],
        ),
      ),
      child: child,
    );
  }
}
