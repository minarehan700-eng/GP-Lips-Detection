import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/app_lock.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/main.dart';
import 'package:lips_offline/core/app_preferences.dart';
import 'package:lips_offline/screens/lock_screen.dart';
import 'package:lips_offline/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async => en = await translationsFor(const Locale('en')));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpLock(WidgetTester tester,
      {required VoidCallback onUnlocked}) async {
    await tester.pumpWidget(localizedApp(
      LockScreen(onUnlocked: onUnlocked, lock: AppLock()),
    ));
    await tester.pumpAndSettle();
  }

  group('the lock screen', () {
    testWidgets('the right PIN lets you through', (tester) async {
      await AppLock().setPin('4821');
      var unlocked = false;

      await pumpLock(tester, onUnlocked: () => unlocked = true);
      await tester.enterText(find.byType(TextField), '4821');
      await tester.tap(find.text(en.securityUnlock));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });

    testWidgets('the wrong PIN does not, and says so', (tester) async {
      await AppLock().setPin('4821');
      var unlocked = false;

      await pumpLock(tester, onUnlocked: () => unlocked = true);
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.text(en.securityUnlock));
      await tester.pumpAndSettle();

      expect(unlocked, isFalse);
      expect(find.text(en.securityWrong), findsOneWidget);
    });

    testWidgets('the field is cleared after a wrong try', (tester) async {
      // Otherwise the failed PIN sits on screen for the next person to read.
      await AppLock().setPin('4821');

      await pumpLock(tester, onUnlocked: () {});
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.text(en.securityUnlock));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
          isEmpty);
    });

    testWidgets('the PIN is not readable on screen', (tester) async {
      await AppLock().setPin('4821');

      await pumpLock(tester, onUnlocked: () {});

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isTrue);
    });

    testWidgets('repeated failures report the lock-out, not just a bad PIN',
        (tester) async {
      await AppLock().setPin('4821');

      await pumpLock(tester, onUnlocked: () {});
      for (var i = 0; i < AppLock.freeAttempts + 2; i++) {
        await tester.enterText(find.byType(TextField), '0000');
        await tester.tap(find.text(en.securityUnlock));
        await tester.pumpAndSettle();
      }

      expect(find.text(en.securityLockedOut), findsOneWidget);
    });
  });

  group('starting the app', () {
    testWidgets('goes straight in when no PIN is set', (tester) async {
      await tester.pumpWidget(LipsOfflineApp(
        preferences: AppPreferencesController(),
        startLocked: false,
      ));
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('shows the lock before anything else when a PIN is set',
        (tester) async {
      // The app must not draw itself and then cover it up — that would leak
      // whatever was underneath for a frame.
      await tester.pumpWidget(LipsOfflineApp(
        preferences: AppPreferencesController(),
        startLocked: true,
      ));
      await tester.pump();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
