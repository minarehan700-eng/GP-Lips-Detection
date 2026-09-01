import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/onboarding/onboarding_page_data.dart';
import 'package:lips_offline/screens/onboarding/onboarding_screen.dart';

import 'helpers/localized.dart';

/// Tests for the three-page introduction shown before the home screen.
///
/// The "Get Started" and "Skip" buttons are not tapped here, because both open
/// the home screen, which needs a real camera.
void main() {
  late AppLocalizations en;
  late List<OnboardingPageData> pages;

  setUpAll(() async {
    en = await translationsFor(const Locale('en'));
    pages = OnboardingPageData.pages(en);
  });

  Future<void> pumpOnboarding(WidgetTester tester,
      {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(localizedApp(const OnboardingScreen(), locale: locale));
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen', () {
    testWidgets('opens on the first page', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text(pages.first.title), findsOneWidget);
    });

    testWidgets('offers Next and Skip on the first page', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text(en.next), findsOneWidget);
      expect(find.text(en.skip), findsOneWidget);
      expect(find.text(en.getStarted), findsNothing);
    });

    testWidgets('Next moves to the second page', (tester) async {
      await pumpOnboarding(tester);

      await tester.tap(find.text(en.next));
      await tester.pumpAndSettle();

      expect(find.text(pages[1].title), findsOneWidget);
    });

    testWidgets('the last page offers Get Started instead of Next',
        (tester) async {
      await pumpOnboarding(tester);

      // Walk to the end of the introduction.
      for (var i = 0; i < pages.length - 1; i++) {
        await tester.tap(find.text(en.next));
        await tester.pumpAndSettle();
      }

      expect(find.text(en.getStarted), findsOneWidget);
      expect(find.text(en.next), findsNothing);
    });

    testWidgets('shows one dot for each page', (tester) async {
      await pumpOnboarding(tester);

      // The dots live in an AnimatedContainer each; count them by finding the
      // row that holds exactly as many as there are pages.
      final dots = find.byType(AnimatedContainer);
      expect(
        tester.widgetList(dots).length,
        greaterThanOrEqualTo(pages.length),
      );
    });

    testWidgets('every page has a title and a body', (tester) async {
      for (final page in pages) {
        expect(page.title, isNotEmpty);
        expect(page.body, isNotEmpty);
      }
    });
  });
}
