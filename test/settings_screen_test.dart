import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/app_theme.dart';
import 'package:lips_offline/core/detector_settings.dart';
import 'package:lips_offline/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the settings screen and the save workflow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SettingsScreen', () {
    testWidgets('shows one slider for each of the three settings',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpSettings(tester);

      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.text('Detector thresholds'), findsOneWidget);
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

      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings saved'), findsOneWidget);
    });

    testWidgets('saving really writes the values to storage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpSettings(tester);

      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      final stored = await DetectorSettings.load();
      expect(stored.mouthOpenThreshold, DetectorSettings.defaultMouthOpen);
      expect(stored.motionThreshold, DetectorSettings.defaultMotion);
      expect(stored.letterMinScore, DetectorSettings.defaultLetterMinScore);
    });

    testWidgets('Reset to defaults puts the sliders back', (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.${DetectorSettings.mouthOpenKey}': 0.65,
      });
      await pumpSettings(tester);
      expect(find.text('0.65'), findsOneWidget);

      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();

      // Nothing is written until the user presses Save.
      final stored = await DetectorSettings.load();
      expect(stored.mouthOpenThreshold, 0.65);
    });
  });
}
