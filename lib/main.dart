import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_preferences.dart';
import 'core/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';

/// Where the app starts.
///
/// `ensureInitialized()` must be called before `runApp` because the app talks
/// to the platform (camera, saved settings, the MediaPipe method channel), and
/// that machinery has to be ready first.
///
/// The saved language is read before the first frame. Loading it later would
/// show the splash screen in the wrong language and then visibly swap it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppPreferencesController(await AppPreferences.load());
  runApp(LipsOfflineApp(preferences: controller));
}

/// The root widget: it sets the dark theme, the language, and the first screen.
///
/// Screen order is: splash → onboarding → home, with settings reachable from
/// home. Each screen decides when to move on, so the whole journey can be
/// followed by reading the screens in that order.
class LipsOfflineApp extends StatelessWidget {
  const LipsOfflineApp({super.key, required this.preferences});

  final AppPreferencesController preferences;

  @override
  Widget build(BuildContext context) {
    return AppPreferencesScope(
      notifier: preferences,
      // Rebuilds the MaterialApp when the language changes, so switching it in
      // Settings takes effect at once instead of on the next launch.
      child: ValueListenableBuilder<AppPreferences>(
        valueListenable: preferences,
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // The task-switcher title has to come from the locale being used,
            // which is not resolved until MaterialApp is building — hence
            // onGenerateTitle rather than a fixed title.
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.dark(),
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
