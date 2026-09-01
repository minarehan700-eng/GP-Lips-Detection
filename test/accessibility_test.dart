import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/application/lip_letter_detector.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/onboarding/onboarding_screen.dart';
import 'package:lips_offline/widgets/lips_detection_panels.dart';

import 'helpers/fake_frames.dart';
import 'helpers/localized.dart';

/// Tests for the app being usable without sight, and readable at large text
/// sizes.
///
/// This matters more here than in most apps: the people it is built for may be
/// deaf, and some of them are also blind or low-vision. A detection that only
/// ever appears as coloured text is no use to them.
void main() {
  late AppLocalizations en;

  setUpAll(() async => en = await translationsFor(const Locale('en')));

  group('letter chips', () {
    testWidgets('each chip is announced as a button with its letter',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpLocalizedPanel();

      for (final letter in LipLetterDetector.supportedLetters) {
        expect(
          find.bySemanticsLabel(en.a11yLetterChip(letter)),
          findsOneWidget,
          reason: 'letter $letter has no spoken name',
        );
      }
      handle.dispose();
    });

    testWidgets('the chosen target is announced as selected', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpLocalizedPanel(targetLetter: 'C');

      // Selection is shown with a blue border; without this the only way to
      // know which letter is being practised is to see that colour.
      expect(
        find.bySemanticsLabel(en.a11yLetterChipSelected('C')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(en.a11yLetterChipSelected('C')),
        ),
        containsSemantics(
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a chip does not read its letter out twice', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpLocalizedPanel();

      // The Text inside is excluded, so "A" should not also appear as a node
      // of its own next to the labelled button.
      expect(find.bySemanticsLabel('A'), findsNothing);
      handle.dispose();
    });

    testWidgets('every chip carries a tap action, not just a label',
        (tester) async {
      // The bug this guards against: wrapping the chip in Semantics with
      // excludeSemantics discarded the child's tap action, so each chip
      // announced itself as a button that a screen reader then could not
      // press. tester.tap did not notice, because it hit-tests a point on the
      // glass rather than performing the node's action - so the assertion has
      // to be on the action existing.
      final handle = tester.ensureSemantics();

      await tester.pumpLocalizedPanel();

      for (final letter in LipLetterDetector.supportedLetters) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(en.a11yLetterChip(letter))),
          containsSemantics(isButton: true, hasTapAction: true),
          reason: 'letter $letter cannot be activated by a screen reader',
        );
      }
      handle.dispose();
    });

    testWidgets('tapping a chip reports the letter', (tester) async {
      String? tapped;

      await tester.pumpLocalizedPanel(onLetterTap: (l) => tapped = l);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(tapped, 'B');
    });
  });

  group('large text', () {
    testWidgets('onboarding survives the largest accessibility text size',
        (tester) async {
      // Someone with low vision may run the system font at 2x or more. The
      // check is simply that nothing throws and nothing overflows.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: localizedApp(const OnboardingScreen()),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

extension on WidgetTester {
  /// Pumps the letter panel with translations in place.
  Future<void> pumpLocalizedPanel({
    String? targetLetter,
    void Function(String letter)? onLetterTap,
  }) async {
    await pumpWidget(localizedApp(
      Scaffold(
        body: DetectedLetterPanel(
          result: frame(),
          targetLetter: targetLetter,
          onLetterTap: onLetterTap ?? (_) {},
        ),
      ),
    ));
    await pumpAndSettle();
  }
}
