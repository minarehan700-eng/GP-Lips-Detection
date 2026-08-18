import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandBlue = Color(0xFF4A63FF);
  static const Color brandPurple = Color(0xFF8B5CFF);
  static const Color brandTeal = Color(0xFF10C8C8);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0C1022),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brandTeal,
        thumbColor: brandTeal,
        inactiveTrackColor: Colors.white24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1FFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
