import 'package:flutter/material.dart'; // Flutter UI

import '../core/app_theme.dart'; // ألوان العلامة

class GradientBackground extends StatelessWidget { // خلفية بتدرج لوني
  const GradientBackground({ // مُنشئ
    required this.child, // المحتوى فوق الخلفية
    super.key, //
  }); //

  final Widget child; // الابن

  @override // تجاوز build
  Widget build(BuildContext context) { // بناء الخلفية
    return Container( // حاوية بخلفية
      decoration: const BoxDecoration( // تنسيق الخلفية
        gradient: LinearGradient( // تدرج خطي
          begin: Alignment.topLeft, // من أعلى اليسار
          end: Alignment.bottomRight, // إلى أسفل اليمين
          colors: [ // الألوان
            Color(0xFF0C1022), // أزرق داكن جداً
            Color(0xFF191D39), // بنفسجي داكن
            AppTheme.brandPurple, // بنفسجي العلامة
          ], //
          stops: [0.0, 0.58, 1.0], // مواقع التوقف
        ), //
      ), //
      child: child, // المحتوى
    ); //
  } // نهاية build
} // نهاية GradientBackground
