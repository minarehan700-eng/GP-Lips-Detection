import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedBrandText extends StatefulWidget {
  const AnimatedBrandText({
    super.key,
    this.text = 'Lips',
    this.fontSize = 34,
    this.weight = FontWeight.w800,
    this.letterSpacing = 0.6,
  });

  final String text;
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 + t * 2, -1),
              end: Alignment(1 + t * 2, 1),
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
              for (var i = 0; i < widget.text.length; i++)
                Transform.translate(
                  offset: Offset(0, math.sin((t * math.pi * 2) + i * 0.6) * 2.2),
                  child: Text(
                    widget.text[i],
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
