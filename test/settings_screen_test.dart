import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/detector_settings.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized.dart';

/// Tests for the settings screen and the save workflow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async => en = await translationsFor(const Locale('en')));

  Future<void> pumpSettings(WidgetTester tester,
      {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(localizedApp(const SettingsScreen(), locale: locale));
    await tester.pumpAndSettle();
  }

  /// Scrolls a control into view, then taps it.
  ///
  /// The screen is a SingleChildScrollView and the buttons sit at the bottom,
  /// below the fold on a test-sized window. Tapping without scrolling first
  /// hits nothing, and the test then fails on the missing result rather than
  /// on the tap - which is exactly what happened when the language card was
  /// added and pushed the buttons further down.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('SettingsScreen', () {
    testWidgets('shows one slider for each of the three settings',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpSettings(tester);

      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.text(en.detectorThresholds), findsOneWidget);
    });

    testWidgets('shows the saved values, not the defaults', (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.${DetectorSettings.mouthOpenKey}': 0.45,
      });

      await pumpSettings(tester);

      // The mouth-open slider is displayed with two decimal places.
      expect(find.text('0.45'), findsOneWidget);
    });

    testWidgets('confirms to the user after saving', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpSettings(tester);

      await scrollAndTap(tester, find.text(en.saveSettings));

      expect(find.text(en.settingsSaved), findsOneWidget);
    });

    testWidgets('saving really writes the values to storage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpSettings(tester);

      // Storage starts empty, so the keys existing afterwards is what proves
      // the write happened. Checking the values alone passed even when the tap
      // missed the button, because load() returns those same defaults when
      // nothing is stored at all.
      final before = await SharedPreferences.getInstance();
      expect(before.getDouble(DetectorSettings.mouthOpenKey), isNull);

      await scrollAndTap(tester, find.text(en.saveSettings));

      final after = await SharedPreferences.getInstance();
      await after.reload();
      expect(after.getDouble(DetectorSettings.mouthOpenKey),
          DetectorSettings.defaultMouthOpen);
      expect(after.getDouble(DetectorSettings.motionKey),
          DetectorSettings.defaultMotion);
      expect(after.getDouble(DetectorSettings.letterMinScoreKey),
          DetectorSettings.defaultLetterMinScore);
    });

    testWidgets('Reset to defaults puts the sliders back', (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.${DetectorSettings.mouthOpenKey}': 0.65,
      });
      await pumpSettings(tester);
      expect(find.text('0.65'), findsOneWidget);

      await scrollAndTap(tester, find.text(en.resetDefaults));

      expect(
        find.text(DetectorSettings.defaultMouthOpen.toStringAsFixed(2)),
        findsOneWidget,
      );
    });

    testWidgets('resetting alone does not overwrite what is stored',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.${DetectorSettings.mouthOpenKey}': 0.65,
      });
      await pumpSettings(tester);

      await scrollAndTap(tester, find.text(en.resetDefaults));

      // Nothing is written until the user presses Save.
      final stored = await DetectorSettings.load();
      expect(stored.mouthOpenThreshold, 0.65);
    });
  });
}
