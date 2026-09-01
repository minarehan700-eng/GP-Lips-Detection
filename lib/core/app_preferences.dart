import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// The choices that shape how the app presents itself, rather than how it
/// detects.
///
/// Why this is separate from `DetectorSettings`:
/// those are numbers the detectors read every frame. These are about language
/// and access needs, are read when a widget builds, and one of them — the
/// language — has to be known before the first screen is drawn.
@immutable
class AppPreferences {
  const AppPreferences({
    this.localeCode,
    this.hapticsEnabled = true,
    this.announceDetections = true,
    this.onboardingSeen = false,
  });

  static const localeKey = 'locale_code';
  static const onboardingSeenKey = 'onboarding_seen';
  static const hapticsKey = 'haptics_enabled';
  static const announceKey = 'announce_detections';

  /// Language chosen by the user, e.g. `ar`. Null means "follow the device",
  /// which is what most people want and so is the default.
  final String? localeCode;

  /// Vibrate when the mouth shape matches the letter being practised.
  ///
  /// On by default: the people this app is built for may not hear a sound, and
  /// a buzz is the one confirmation that does not require looking at the
  /// screen while you are also holding your face in front of the camera.
  final bool hapticsEnabled;

  /// Send each detection to the screen reader.
  ///
  /// On by default. With it off, a screen-reader user gets no feedback at all,
  /// because the result only ever appears as text that never takes focus.
  final bool announceDetections;

  /// Whether the three intro pages have already been read.
  ///
  /// They used to be shown on every single launch, which is fine the first
  /// time and irritating the twentieth.
  final bool onboardingSeen;

  /// The languages the app ships with, taken from the generated localizations
  /// so this list cannot drift away from the .arb files.
  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  /// [localeCode] as a [Locale], or null to follow the device.
  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  static Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(localeKey);
    return AppPreferences(
      // A language that was dropped from the app since it was chosen would
      // otherwise leave the user on a locale with no translations.
      localeCode: isSupported(stored) ? stored : null,
      hapticsEnabled: prefs.getBool(hapticsKey) ?? true,
      announceDetections: prefs.getBool(announceKey) ?? true,
      onboardingSeen: prefs.getBool(onboardingSeenKey) ?? false,
    );
  }

  /// Whether [code] is a language this build actually carries.
  static bool isSupported(String? code) {
    if (code == null) {
      return false;
    }
    return supportedLocales.any((locale) => locale.languageCode == code);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    if (localeCode == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, localeCode!);
    }
    await prefs.setBool(hapticsKey, hapticsEnabled);
    await prefs.setBool(announceKey, announceDetections);
    await prefs.setBool(onboardingSeenKey, onboardingSeen);
  }

  AppPreferences copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? hapticsEnabled,
    bool? announceDetections,
    bool? onboardingSeen,
  }) {
    return AppPreferences(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      announceDetections: announceDetections ?? this.announceDetections,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.localeCode == localeCode &&
      other.hapticsEnabled == hapticsEnabled &&
      other.announceDetections == announceDetections &&
      other.onboardingSeen == onboardingSeen;

  @override
  int get hashCode => Object.hash(
      localeCode, hapticsEnabled, announceDetections, onboardingSeen);
}

/// Holds the live [AppPreferences] and writes changes back to the phone.
///
/// Changing the language has to redraw the whole app, so this sits above
/// `MaterialApp` rather than inside any one screen.
class AppPreferencesController extends ValueNotifier<AppPreferences> {
  AppPreferencesController([super.initial = const AppPreferences()]);

  /// Replaces the preferences and saves them.
  Future<void> update(AppPreferences next) async {
    if (next == value) {
      return;
    }
    value = next;
    await next.save();
  }

  Future<void> setLocale(String? code) => update(
        code == null
            ? value.copyWith(clearLocale: true)
            : value.copyWith(localeCode: code),
      );

  Future<void> setHaptics(bool enabled) =>
      update(value.copyWith(hapticsEnabled: enabled));

  Future<void> setAnnounceDetections(bool enabled) =>
      update(value.copyWith(announceDetections: enabled));

  Future<void> markOnboardingSeen() =>
      update(value.copyWith(onboardingSeen: true));
}

/// Makes the controller reachable from any screen.
class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    super.key,
    required AppPreferencesController super.notifier,
    required super.child,
  });

  static AppPreferencesController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope?.notifier != null, 'No AppPreferencesScope above this widget');
    return scope!.notifier!;
  }

  /// The current preferences, for widgets that only need to read them.
  static AppPreferences settingsOf(BuildContext context) => of(context).value;
}
