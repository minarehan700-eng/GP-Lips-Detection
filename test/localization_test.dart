import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/app_preferences.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/onboarding/onboarding_page_data.dart';
import 'package:lips_offline/screens/onboarding/onboarding_screen.dart';
import 'package:lips_offline/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized.dart';

/// Tests for shipping the app in more than one language.
///
/// The .arb files are read from disk here rather than through the generated
/// code, because the point is to catch a translator's mistake — a missing key,
/// a placeholder typed wrongly — before it reaches a build.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Plain throw rather than expect(): this is also called while collecting the
  // tests, where expect() is not allowed.
  Map<String, dynamic> readArb(String code) {
    final file = File('lib/l10n/app_$code.arb');
    if (!file.existsSync()) {
      throw StateError('lib/l10n/app_$code.arb is missing');
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  List<String> keysOf(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toList();

  /// Placeholders such as {percent} that a translation has to carry over.
  Set<String> placeholdersIn(String value) => RegExp(r'\{(\w+)\}')
      .allMatches(value)
      .map((m) => m.group(1)!)
      .toSet();

  final template = readArb('en');
  final templateKeys = keysOf(template);
  final otherCodes =
      AppLocalizations.supportedLocales.map((l) => l.languageCode).where((c) => c != 'en');

  group('translation files', () {
    test('every supported locale has an .arb file', () {
      for (final code in AppLocalizations.supportedLocales.map((l) => l.languageCode)) {
        expect(File('lib/l10n/app_$code.arb').existsSync(), isTrue,
            reason: '$code is offered but has no translations');
      }
    });

    for (final code in otherCodes) {
      test('$code translates every key and nothing extra', () {
        final keys = keysOf(readArb(code));
        expect(
          templateKeys.where((k) => !keys.contains(k)),
          isEmpty,
          reason: '$code is missing keys, so those strings would fall back to '
              'English without anyone noticing',
        );
        expect(
          keys.where((k) => !templateKeys.contains(k)),
          isEmpty,
          reason: '$code has keys English does not, which are dead weight',
        );
      });

      test('$code keeps every placeholder intact', () {
        final arb = readArb(code);
        for (final key in templateKeys) {
          final expected = placeholdersIn(template[key] as String);
          final actual = placeholdersIn(arb[key] as String);
          expect(actual, expected,
              reason: 'placeholders differ for "$key" in $code — a missing one '
                  'renders as literal text, an invented one throws');
        }
      });

      test('$code leaves nothing untranslated', () {
        // A string identical to the English one is usually a key someone
        // forgot. Sometimes it is simply the right answer, so those are listed
        // rather than the check being dropped.
        const sameByDesign = <String, Set<String>>{
          // The brand name is not translated in any language, and
          // "{hits}/{attempts}" is two numbers and a slash - there is nothing
          // in it to translate.
          '*': {'appTitle', 'brandName', 'progressAttempts'},
          // "No" really is "No" in Spanish.
          'es': {'no'},
        };
        final allowed = {...sameByDesign['*']!, ...?sameByDesign[code]};

        final arb = readArb(code);
        final same = templateKeys
            .where((k) => !allowed.contains(k))
            .where((k) => arb[k] == template[k])
            .toList();
        expect(same, isEmpty,
            reason: 'still identical to English in $code: $same');
      });
    }

    test('the page count constant matches the pages actually built', () async {
      final en = await translationsFor(const Locale('en'));
      expect(OnboardingPageData.pages(en).length, OnboardingPageData.pageCount);
    });
  });

  group('the app in another language', () {
    testWidgets('onboarding is shown in Arabic', (tester) async {
      final ar = await translationsFor(const Locale('ar'));

      await tester.pumpWidget(
          localizedApp(const OnboardingScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text(ar.onboardLipsingTitle), findsOneWidget);
      expect(find.text(ar.skip), findsOneWidget);
    });

    testWidgets('Arabic lays the interface out right to left', (tester) async {
      await tester.pumpWidget(
          localizedApp(const OnboardingScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final direction = Directionality.of(
        tester.element(find.byType(OnboardingScreen)),
      );
      expect(direction, TextDirection.rtl);
    });

    testWidgets('English lays it out left to right', (tester) async {
      await tester.pumpWidget(localizedApp(const OnboardingScreen()));
      await tester.pumpAndSettle();

      final direction = Directionality.of(
        tester.element(find.byType(OnboardingScreen)),
      );
      expect(direction, TextDirection.ltr);
    });

    testWidgets('settings offers one choice per shipped language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final en = await translationsFor(const Locale('en'));

      await tester.pumpWidget(localizedApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      final picker = find.text(en.languageSystem);
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();

      // One chip per language, plus "match my device".
      expect(find.byType(ChoiceChip),
          findsNWidgets(AppLocalizations.supportedLocales.length + 1));
    });

    testWidgets('choosing a language redraws the app in it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppPreferencesController();
      final ar = await translationsFor(const Locale('ar'));

      await tester.pumpWidget(localizedApp(
        const SettingsScreen(),
        preferences: controller,
      ));
      await tester.pumpAndSettle();

      await controller.setLocale('ar');
      expect(controller.value.localeCode, 'ar');
      expect(ar.settings, isNot(equals('Settings')));
    });
  });

  group('remembering the choice', () {
    test('an unknown stored language falls back to the device', () async {
      // A language dropped from a later build would otherwise leave the user
      // stranded on a locale with no translations at all.
      SharedPreferences.setMockInitialValues({
        'flutter.${AppPreferences.localeKey}': 'kl',
      });

      final loaded = await AppPreferences.load();

      expect(loaded.localeCode, isNull);
    });

    test('a supported stored language is kept', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.${AppPreferences.localeKey}': 'ar',
      });

      final loaded = await AppPreferences.load();

      expect(loaded.localeCode, 'ar');
      expect(loaded.locale, const Locale('ar'));
    });

    test('accessibility helps are on unless turned off', () async {
      SharedPreferences.setMockInitialValues({});

      final loaded = await AppPreferences.load();

      expect(loaded.hapticsEnabled, isTrue);
      expect(loaded.announceDetections, isTrue);
    });

    test('turning them off survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppPreferencesController(await AppPreferences.load());

      await controller.setHaptics(false);
      await controller.setAnnounceDetections(false);
      await controller.setLocale('fr');

      final reloaded = await AppPreferences.load();
      expect(reloaded.hapticsEnabled, isFalse);
      expect(reloaded.announceDetections, isFalse);
      expect(reloaded.localeCode, 'fr');
    });

    test('onboarding is not marked as read until it has been', () async {
      SharedPreferences.setMockInitialValues({});

      expect((await AppPreferences.load()).onboardingSeen, isFalse);
    });

    test('once read, onboarding stays read across launches', () async {
      // It used to reappear on every single launch - helpful once, tiresome
      // by the tenth time.
      SharedPreferences.setMockInitialValues({});
      final controller = AppPreferencesController(await AppPreferences.load());

      await controller.markOnboardingSeen();

      expect((await AppPreferences.load()).onboardingSeen, isTrue);
    });

    test('changing the language does not forget that it was read', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppPreferencesController(await AppPreferences.load());
      await controller.markOnboardingSeen();

      await controller.setLocale('fr');

      final reloaded = await AppPreferences.load();
      expect(reloaded.onboardingSeen, isTrue);
      expect(reloaded.localeCode, 'fr');
    });

    test('going back to the device language clears the stored choice',
        () async {
      SharedPreferences.setMockInitialValues({
        'flutter.${AppPreferences.localeKey}': 'es',
      });
      final controller = AppPreferencesController(await AppPreferences.load());

      await controller.setLocale(null);

      expect((await AppPreferences.load()).localeCode, isNull);
    });
  });
}
