import 'dart:ui'; // ImageFilter للضبابية (blur)

import 'package:flutter/material.dart'; // Flutter UI

class GlassCard extends StatelessWidget { // بطاقة زجاجية شفافة (glassmorphism)
  const GlassCard({ // مُنشئ
    required this.child, // المحتوى الداخلي
    super.key, //
    this.padding = const EdgeInsets.all(16), // حشو داخلي
    this.borderRadius = 20, // نصف قطر الزوايا
    this.opacity = 0.12, // شفافية الخلفية
    this.blur = 18, // قوة الضبابية
  }); //

  final Widget child; // الابن
  final EdgeInsetsGeometry padding; // الحشو
  final double borderRadius; // الزوايا
  final double opacity; // الشفافية
  final double blur; // الblur

  @override // تجاوز build
  Widget build(BuildContext context) { // بناء البطاقة
    return ClipRRect( // قص الزوايا
      borderRadius: BorderRadius.circular(borderRadius), //
      child: BackdropFilter( // ضبابية ما خلف البطاقة
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), //
        child: Container( // حاوية البطاقة
          padding: padding, //
          decoration: BoxDecoration( // تنسيق
            borderRadius: BorderRadius.circular(borderRadius), //
            gradient: LinearGradient( // تدرج خفيف
              begin: Alignment.topLeft, //
              end: Alignment.bottomRight, //
              colors: [ //
                Colors.white.withValues(alpha: opacity + 0.08), //
                Colors.white.withValues(alpha: opacity), //
              ], //
            ), //
            border: Border.all(color: Colors.white24), // حدود فاتحة
          ), //
          child: child, // المحتوى
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية GlassCard
