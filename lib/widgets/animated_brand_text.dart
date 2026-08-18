import 'dart:math' as math; // sin للحركة

import 'package:flutter/material.dart'; // Flutter UI

class AnimatedBrandText extends StatefulWidget { // نص العلامة متحرك
  const AnimatedBrandText({ // مُنشئ
    super.key, //
    this.text = 'Lips', // النص الافتراضي
    this.fontSize = 34, // حجم الخط
    this.weight = FontWeight.w800, // سُمك الخط
    this.letterSpacing = 0.6, // تباعد الحروف
  }); //

  final String text; // النص
  final double fontSize; // الحجم
  final FontWeight weight; // السُمك
  final double letterSpacing; // التباعد

  @override // createState
  State<AnimatedBrandText> createState() => _AnimatedBrandTextState(); //
} // نهاية AnimatedBrandText

class _AnimatedBrandTextState extends State<AnimatedBrandText> // حالة النص المتحرك
    with SingleTickerProviderStateMixin { // mixin للـ AnimationController
  late final AnimationController _controller; // متحكم الحركة

  @override // initState
  void initState() { // تهيئة
    super.initState(); //
    _controller = AnimationController( // إنشاء المتحكم
      vsync: this, // ربط بالشاشة
      duration: const Duration(milliseconds: 1900), // مدة دورة
    )..repeat(reverse: true); // تكرار ذهاب وإياب
  } // نهاية initState

  @override // dispose
  void dispose() { // تنظيف
    _controller.dispose(); //
    super.dispose(); //
  } // نهاية dispose

  @override // build
  Widget build(BuildContext context) { // بناء النص
    return AnimatedBuilder( // يعيد البناء مع كل frame
      animation: _controller, //
      builder: (context, _) { // دالة البناء
        final t = _controller.value; // قيمة 0..1
        return ShaderMask( // قناع تدرج على النص
          shaderCallback: (rect) { // callback للتدرج
            return LinearGradient( // تدرج متحرك
              begin: Alignment(-1 + t * 2, -1), // بداية تتحرك
              end: Alignment(1 + t * 2, 1), // نهاية تتحرك
              colors: const [ // ألوان التدرج
                Color(0xFF7CC7FF), //
                Color(0xFFD2A8FF), //
                Color(0xFF75F7D3), //
              ], //
            ).createShader(rect); // إنشاء shader
          }, //
          blendMode: BlendMode.srcIn, // وضع المزج
          child: Row( // صف حروف
            mainAxisSize: MainAxisSize.min, //
            children: [ //
              for (var i = 0; i < widget.text.length; i++) // لكل حرف
                Transform.translate( // إزاحة عمودية (موجة)
                  offset: Offset(0, math.sin((t * math.pi * 2) + i * 0.6) * 2.2), //
                  child: Text( // الحرف
                    widget.text[i], //
                    style: TextStyle( // تنسيق
                      fontSize: widget.fontSize, //
                      fontWeight: widget.weight, //
                      letterSpacing: widget.letterSpacing, //
                    ), //
                  ), //
                ), //
            ], //
          ), //
        ); //
      }, //
    ); //
  } // نهاية build
} // نهاية _AnimatedBrandTextState
