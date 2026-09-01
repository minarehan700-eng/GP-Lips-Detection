import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_navigation.dart';
import '../core/app_preferences.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_brand_text.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_screen.dart';

/// Splash screen shown on launch; navigates to onboarding after a short delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// How long the logo stays on screen before onboarding opens.
  /// Long enough to read the name, short enough not to feel slow.
  static const Duration splashDuration = Duration(milliseconds: 2200);

  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(splashDuration, _goOnboarding);
  }

  @override
  void dispose() {
    // Cancelled so the timer cannot fire after the screen is gone, which
    // would try to navigate from a widget that no longer exists.
    _splashTimer?.cancel();
    super.dispose();
  }

  /// Replaces the splash once the timer finishes: with onboarding the first
  /// time, and straight to the home screen afterwards.
  ///
  /// The three intro pages used to appear on every single launch, which is
  /// helpful once and tiresome by the tenth time.
  void _goOnboarding() {
    if (!mounted) return;
    final seen = AppPreferencesScope.settingsOf(context).onboardingSeen;
    Navigator.of(context).pushReplacement(
      AppNavigation.fadeTransition(
        seen ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _AnimatedLogoMark()),
            Positioned(
              bottom: 52,
              left: 0,
              right: 0,
              child: Text(
                AppLocalizations.of(context).splashTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The splash logo: two rings turning slowly around a rounded app icon.
///
/// The rings turn in opposite directions and at different speeds, which makes
/// the mark look alive without needing an image file.
class _AnimatedLogoMark extends StatefulWidget {
  @override
  State<_AnimatedLogoMark> createState() => _AnimatedLogoMarkState();
}

class _AnimatedLogoMarkState extends State<_AnimatedLogoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
        final angle = _controller.value * math.pi * 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -angle * 0.7,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.1),
                    ),
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5E7BFF), Color(0xFF9D56FF)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x805A7CFF),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 48),
                ),
              ],
            ).animate().fadeIn(duration: 420.ms).scale(curve: Curves.easeOutBack),
            const SizedBox(height: 22),
            const AnimatedBrandText().animate().fadeIn(delay: 280.ms),
          ],
        );
      },
    );
  }
}
