import 'dart:ui';

import 'package:flutter/material.dart';

/// A translucent "frosted glass" panel used for every card in the app.
///
/// It blurs whatever is behind it and lays a faint white gradient on top, so
/// the gradient background still shows through while the text stays readable.
/// Every card uses this one widget, which keeps the look consistent.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.opacity = 0.12,
    this.blur = 18,
  });

  /// The content placed inside the card.
  final Widget child;

  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// How solid the white overlay is, from 0.0 (invisible) to 1.0 (opaque).
  final double opacity;

  /// How strongly the background behind the card is blurred.
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: opacity + 0.08),
                Colors.white.withValues(alpha: opacity),
              ],
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}
