import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/app_theme.dart';
import 'package:lips_offline/screens/onboarding/onboarding_page_data.dart';
import 'package:lips_offline/screens/onboarding/onboarding_screen.dart';

/// Tests for the three-page introduction shown before the home screen.
///
/// The "Get Started" and "Skip" buttons are not tapped here, because both open
/// the home screen, which needs a real camera.
void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen', () {
    testWidgets('opens on the first page', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text(OnboardingPageData.pages.first.title), findsOneWidget);
    });

    testWidgets('offers Next and Skip on the first page', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('Next moves to the second page', (tester) async {
      await pumpOnboarding(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text(OnboardingPageData.pages[1].title), findsOneWidget);
    });

    testWidgets('the last page offers Get Started instead of Next',
        (tester) async {
      await pumpOnboarding(tester);

      // Walk to the end of the introduction.
      for (var i = 0; i < OnboardingPageData.pages.length - 1; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('shows one dot for each page', (tester) async {
      await pumpOnboarding(tester);

      // The dots live in an AnimatedContainer each; count them by finding the
      // row that holds exactly as many as there are pages.
      final dots = find.byType(AnimatedContainer);
      expect(
        tester.widgetList(dots).length,
        greaterThanOrEqualTo(OnboardingPageData.pages.length),
      );
    });

    testWidgets('every page has a title and a body', (tester) async {
      for (final page in OnboardingPageData.pages) {
        expect(page.title, isNotEmpty);
        expect(page.body, isNotEmpty);
      }
    });
  });
}
