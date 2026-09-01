import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/app_preferences.dart';
import 'package:lips_offline/l10n/app_localizations.dart';

/// Wraps a widget in everything a screen needs to build in a test: the
/// translations, the preferences it reads, and a locale.
///
/// Screens now look up both, so pumping one bare throws. Passing a [locale]
/// also makes it possible to check the app in Arabic, where the layout
/// mirrors.
Widget localizedApp(
  Widget child, {
  Locale locale = const Locale('en'),
  AppPreferencesController? preferences,
}) {
  return AppPreferencesScope(
    notifier: preferences ?? AppPreferencesController(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

/// Pumps [child] with translations in place and settles the animations.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  AppPreferencesController? preferences,
}) async {
  await tester.pumpWidget(
    localizedApp(child, locale: locale, preferences: preferences),
  );
  await tester.pump();
}

/// The translations for [locale], for a test that needs the expected wording
/// without hard-coding English into the assertion.
Future<AppLocalizations> translationsFor(Locale locale) =>
    AppLocalizations.delegate.load(locale);
