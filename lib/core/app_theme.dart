import 'package:flutter/material.dart'; // استيراد Flutter للألوان والثيم

class AppTheme { // كلاس يحدد ألوان وتنسيق التطبيق
  static const Color brandBlue = Color(0xFF4A63FF); // اللون الأزرق الرئيسي للعلامة
  static const Color brandPurple = Color(0xFF8B5CFF); // اللون البنفسجي
  static const Color brandTeal = Color(0xFF10C8C8); // اللون الفيروزي (للتمييز)

  static ThemeData dark() { // دالة ترجع ثيم داكن جاهز
    final scheme = ColorScheme.fromSeed( // إنشاء لوحة ألوان من لون البذرة
      seedColor: brandBlue, // اللون الأساسي
      brightness: Brightness.dark, // وضع داكن
    ); // نهاية ColorScheme
    return ThemeData( // بناء ThemeData
      useMaterial3: true, // استخدام Material Design 3
      colorScheme: scheme, // تطبيق لوحة الألوان
      scaffoldBackgroundColor: const Color(0xFF0C1022), // خلفية الشاشات الداكنة
      appBarTheme: const AppBarTheme( // تنسيق شريط العنوان
        backgroundColor: Colors.transparent, // شفاف ليرى التدرج خلفه
        elevation: 0, // بدون ظل
      ), // نهاية AppBarTheme
      sliderTheme: SliderThemeData( // تنسيق أشرطة التمرير (Sliders)
        activeTrackColor: brandTeal, // لون الجزء المفعّل
        thumbColor: brandTeal, // لون مقبض السحب
        inactiveTrackColor: Colors.white24, // لون الجزء غير المفعّل
      ), // نهاية SliderTheme
      inputDecorationTheme: InputDecorationTheme( // تنسيق حقول الإدخال
        filled: true, // خلفية مملوءة
        fillColor: const Color(0x1FFFFFFF), // لون شفاف فاتح
        border: OutlineInputBorder( // شكل الحدود
          borderRadius: BorderRadius.circular(16), // زوايا دائرية
          borderSide: BorderSide.none, // بدون خط حدود
        ), // نهاية OutlineInputBorder
      ), // نهاية InputDecorationTheme
    ); // نهاية ThemeData
  } // نهاية dark
} // نهاية AppTheme
