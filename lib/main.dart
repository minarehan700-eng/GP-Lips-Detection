import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_lock.dart';
import 'core/app_preferences.dart';
import 'core/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/lock_screen.dart';
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
  // Asked before the first frame: showing the app and then covering it would
  // have leaked whatever was on screen underneath.
  final locked = await AppLock().isEnabled;
  runApp(LipsOfflineApp(preferences: controller, startLocked: locked));
}

/// The root widget: it sets the dark theme, the language, and the first screen.
///
/// Screen order is: splash → onboarding → home, with settings reachable from
/// home. Each screen decides when to move on, so the whole journey can be
/// followed by reading the screens in that order.
class LipsOfflineApp extends StatefulWidget {
  const LipsOfflineApp({
    super.key,
    required this.preferences,
    this.startLocked = false,
  });

  final AppPreferencesController preferences;

  /// Whether a PIN has been set and has yet to be entered.
  final bool startLocked;

  @override
  State<LipsOfflineApp> createState() => _LipsOfflineAppState();
}

class _LipsOfflineAppState extends State<LipsOfflineApp> {
  late bool _locked = widget.startLocked;

  @override
  Widget build(BuildContext context) {
    return AppPreferencesScope(
      notifier: widget.preferences,
      // Rebuilds the MaterialApp when the language changes, so switching it in
      // Settings takes effect at once instead of on the next launch.
      child: ValueListenableBuilder<AppPreferences>(
        valueListenable: widget.preferences,
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
            home: _locked
                ? LockScreen(onUnlocked: () => setState(() => _locked = false))
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}
