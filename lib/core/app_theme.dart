import 'package:flutter/material.dart';

/// All colours and the Material theme used across the app.
///
/// Why this class exists:
/// Keeping every colour in one file means a change here updates every screen
/// at once, and no colour code is repeated in several widgets.
class AppTheme {
  /// Main brand colour; also the seed Material uses to build the palette.
  static const Color brandBlue = Color(0xFF4A63FF);

  /// Used in the background gradient.
  static const Color brandPurple = Color(0xFF8B5CFF);

  /// Highlight colour for detected values, sliders and the mouth box.
  static const Color brandTeal = Color(0xFF10C8C8);

  /// Positive/active colour: lipsing detected, target letter matched.
  static const Color successGreen = Color(0xFF4ADE80);

  /// Page background behind the gradient.
  static const Color darkBackground = Color(0xFF0C1022);

  /// Builds the dark Material 3 theme.
  ///
  /// A dark theme is used because the camera preview and the coloured status
  /// text stand out far better against a dark background.
  static ThemeData dark() {
    // Material builds a full matching palette from one seed colour, so the
    // app only has to choose the brand colour.
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      // Transparent, so the gradient background shows through the app bar.
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
