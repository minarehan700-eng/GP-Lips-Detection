import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

/// App entry point — initializes Flutter and launches the root widget.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LipsOfflineApp());
}

/// Root MaterialApp with dark theme; starts on the splash screen.
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
