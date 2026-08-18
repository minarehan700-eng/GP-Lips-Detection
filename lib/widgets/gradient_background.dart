import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C1022),
            Color(0xFF191D39),
            AppTheme.brandPurple,
          ],
          stops: [0.0, 0.58, 1.0],
        ),
      ),
      child: child,
    );
  }
}
