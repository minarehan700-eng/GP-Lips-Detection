import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/main.dart';
import 'package:lips_offline/screens/onboarding/onboarding_page_data.dart';
import 'package:lips_offline/screens/onboarding/onboarding_screen.dart';
import 'package:lips_offline/core/app_preferences.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized.dart';

/// Start-up test for the whole app.
///
/// It checks the first part of the journey a user sees: the app opens on the
/// splash screen and moves on to onboarding by itself.
///
/// The home screen is not reached here on purpose — it opens the camera, which
/// does not exist in a test.
///
/// Note on timing: the splash logo animates forever, so this test steps time
/// forward with `pump(duration)` instead of `pumpAndSettle()`, which would
/// wait for an animation that never finishes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async => en = await translationsFor(const Locale('en')));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The whole app, with the preferences it now needs above MaterialApp.
  Widget buildApp() => LipsOfflineApp(preferences: AppPreferencesController());

  /// Steps time past the splash delay and the page transition.
  ///
  /// Every test must do this before it finishes, otherwise the splash timer is
  /// still waiting when the test ends and the test framework reports it as a
  /// leaked timer.
  Future<void> leaveSplashScreen(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('the app opens on the splash screen', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(en.splashTagline), findsOneWidget);

    await leaveSplashScreen(tester);
  });

  testWidgets('the splash screen moves on to onboarding by itself',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await leaveSplashScreen(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text(OnboardingPageData.pages(en).first.title), findsOneWidget);
  });

  testWidgets('the app uses a dark theme', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.dark);
    expect(app.debugShowCheckedModeBanner, isFalse);

    await leaveSplashScreen(tester);
  });
}
