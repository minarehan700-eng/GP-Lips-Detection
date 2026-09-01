import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The app name on the splash screen, with a moving colour gradient and
/// letters that bob gently up and down.
///
/// Two animations run from one controller: a [ShaderMask] slides a gradient
/// across the text, and each letter is offset by a sine wave. Giving each
/// letter a slightly different point in that wave makes them ripple instead of
/// moving together.
class AnimatedBrandText extends StatefulWidget {
  const AnimatedBrandText({
    super.key,
    this.text,
    this.fontSize = 34,
    this.weight = FontWeight.w800,
    this.letterSpacing = 0.6,
  });

  /// How far one letter is bobbed up or down, in pixels.
  static const double letterWaveHeight = 2.2;

  /// How much later each following letter starts its bob, in radians.
  static const double letterWavePhaseStep = 0.6;

  /// The word to animate. Null means "the app's own name", which has to be
  /// resolved where there is a BuildContext rather than in the constructor.
  final String? text;
  final double fontSize;
  final FontWeight weight;
  final double letterSpacing;

  @override
  State<AnimatedBrandText> createState() => _AnimatedBrandTextState();
}

class _AnimatedBrandTextState extends State<AnimatedBrandText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolved here rather than in the constructor: a default argument has to
    // be a constant, and a translated name is only known once there is a
    // context to look it up in.
    final word = widget.text ?? AppLocalizations.of(context).brandName;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Runs from 0.0 to 1.0 and back again, driving both animations.
        final animationProgress = _controller.value;
        return ShaderMask(
          shaderCallback: (rect) {
            // Both ends of the gradient slide right together, so the colours
            // appear to travel across the word.
            return LinearGradient(
              begin: Alignment(-1 + animationProgress * 2, -1),
              end: Alignment(1 + animationProgress * 2, 1),
              colors: const [
                Color(0xFF7CC7FF),
                Color(0xFFD2A8FF),
                Color(0xFF75F7D3),
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcIn,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // `letterIndex * 0.6` delays each letter a little, turning one
              // shared wave into a ripple along the word.
              for (var letterIndex = 0;
                  letterIndex < word.length;
                  letterIndex++)
                Transform.translate(
                  offset: Offset(
                    0,
                    math.sin((animationProgress * math.pi * 2) +
                            letterIndex *
                                AnimatedBrandText.letterWavePhaseStep) *
                        AnimatedBrandText.letterWaveHeight,
                  ),
                  child: Text(
                    word[letterIndex],
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: widget.weight,
                      letterSpacing: widget.letterSpacing,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
