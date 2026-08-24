import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

/// Where the app starts.
///
/// `ensureInitialized()` must be called before `runApp` because the app talks
/// to the platform (camera, saved settings, the MediaPipe method channel), and
/// that machinery has to be ready first.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LipsOfflineApp());
}

/// The root widget: it sets the dark theme and opens the first screen.
///
/// Screen order is: splash → onboarding → home, with settings reachable from
/// home. Each screen decides when to move on, so the whole journey can be
/// followed by reading the screens in that order.
class LipsOfflineApp extends StatelessWidget {
  const LipsOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lips Offline',
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
