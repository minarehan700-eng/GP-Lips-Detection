import 'dart:async'; // Timer
import 'dart:math' as math; // pi للدوران

import 'package:flutter/material.dart'; // Flutter UI
import 'package:flutter_animate/flutter_animate.dart'; // animations

import '../core/app_navigation.dart'; // انتقالات
import '../widgets/animated_brand_text.dart'; // نص Lips
import '../widgets/gradient_background.dart'; // خلفية
import 'onboarding/onboarding_screen.dart'; // onboarding

class SplashScreen extends StatefulWidget { // شاشة البداية
  const SplashScreen({super.key}); //

  @override // createState
  State<SplashScreen> createState() => _SplashScreenState(); //
} // نهاية SplashScreen

class _SplashScreenState extends State<SplashScreen> { // حالة splash
  Timer? _splashTimer; // مؤقت الانتقال

  @override // initState
  void initState() { //
    super.initState(); //
    _splashTimer = Timer(const Duration(milliseconds: 2200), _goOnboarding); // بعد 2.2 ث
  } // نهاية initState

  @override // dispose
  void dispose() { //
    _splashTimer?.cancel(); //
    super.dispose(); //
  } // نهاية dispose

  void _goOnboarding() { // الانتقال لـ onboarding
    if (!mounted) return; //
    Navigator.of(context).pushReplacement( //
      AppNavigation.fadeTransition(const OnboardingScreen()), //
    ); //
  } // نهاية _goOnboarding

  @override // build
  Widget build(BuildContext context) { //
    return Scaffold( //
      body: GradientBackground( //
        child: Stack( //
          fit: StackFit.expand, //
          children: [ //
            Center(child: _AnimatedLogoMark()), // شعار متحرك
            Positioned( // نص أسفل الشاشة
              bottom: 52, //
              left: 0, //
              right: 0, //
              child: Text( //
                'Detect lipsing and mouth letters A–E', //
                textAlign: TextAlign.center, //
                style: Theme.of(context).textTheme.bodyLarge?.copyWith( //
                      color: Colors.white70, //
                    ), //
              ), //
            ), //
          ], //
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية _SplashScreenState

class _AnimatedLogoMark extends StatefulWidget { // شعار دوّار
  @override // createState
  State<_AnimatedLogoMark> createState() => _AnimatedLogoMarkState(); //
} // نهاية _AnimatedLogoMark

class _AnimatedLogoMarkState extends State<_AnimatedLogoMark> // حالة الشعار
    with SingleTickerProviderStateMixin { //
  late final AnimationController _controller; //

  @override // initState
  void initState() { //
    super.initState(); //
    _controller = AnimationController( //
      vsync: this, //
      duration: const Duration(seconds: 4), //
    )..repeat(); // دوران مستمر
  } // نهاية initState

  @override // dispose
  void dispose() { //
    _controller.dispose(); //
    super.dispose(); //
  } // نهاية dispose

  @override // build
  Widget build(BuildContext context) { //
    return AnimatedBuilder( //
      animation: _controller, //
      builder: (context, _) { //
        final angle = _controller.value * math.pi * 2; // زاوية الدوران
        return Column( //
          mainAxisSize: MainAxisSize.min, //
          children: [ //
            Stack( // دوائر + أيقونة
              alignment: Alignment.center, //
              children: [ //
                Transform.rotate( // دائرة خارجية
                  angle: angle, //
                  child: Container( //
                    width: 148, //
                    height: 148, //
                    decoration: BoxDecoration( //
                      shape: BoxShape.circle, //
                      border: Border.all(color: Colors.white24, width: 1.2), //
                    ), //
                  ), //
                ), //
                Transform.rotate( // دائرة داخلية عكس الاتجاه
                  angle: -angle * 0.7, //
                  child: Container( //
                    width: 118, //
                    height: 118, //
                    decoration: BoxDecoration( //
                      shape: BoxShape.circle, //
                      border: Border.all(color: Colors.white30, width: 1.1), //
                    ), //
                  ), //
                ), //
                Container( // مربع الأيقونة
                  width: 92, //
                  height: 92, //
                  decoration: BoxDecoration( //
                    borderRadius: BorderRadius.circular(30), //
                    gradient: const LinearGradient( //
                      colors: [Color(0xFF5E7BFF), Color(0xFF9D56FF)], //
                    ), //
                    boxShadow: const [ //
                      BoxShadow( //
                        color: Color(0x805A7CFF), //
                        blurRadius: 20, //
                        offset: Offset(0, 8), //
                      ), //
                    ], //
                  ), //
                  child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 48), //
                ), //
              ], //
            ).animate().fadeIn(duration: 420.ms).scale(curve: Curves.easeOutBack), //
            const SizedBox(height: 22), //
            const AnimatedBrandText().animate().fadeIn(delay: 280.ms), //
          ], //
        ); //
      }, //
    ); //
  } // نهاية build
} // نهاية _AnimatedLogoMarkState
