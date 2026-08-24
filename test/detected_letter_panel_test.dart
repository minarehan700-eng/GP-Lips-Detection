import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/application/lip_letter_detector.dart';
import 'package:lips_offline/core/app_theme.dart';
import 'package:lips_offline/widgets/lips_detection_panels.dart';

import 'helpers/fake_frames.dart';

/// Tests for the panel that shows the detected letter and the practice chips.
///
/// This covers the main practice workflow: pick a target letter, then see
/// "Matched!" when your mouth shape agrees with it.
void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    String? detectedLetter,
    double confidence = 0,
    String? targetLetter,
    void Function(String letter)? onLetterTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: DetectedLetterPanel(
            result: frame().copyWith(
              detectedLetter: detectedLetter,
              letterConfidence: confidence,
            ),
            targetLetter: targetLetter,
            onLetterTap: onLetterTap ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DetectedLetterPanel', () {
    testWidgets('shows a dash when nothing is detected', (tester) async {
      await pumpPanel(tester);

      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('confidence'), findsNothing);
    });

    testWidgets('shows the detected letter and its confidence',
        (tester) async {
      await pumpPanel(tester, detectedLetter: 'C', confidence: 0.82);

      expect(find.text('82% confidence'), findsOneWidget);
    });

    testWidgets('offers a chip for every supported letter', (tester) async {
      await pumpPanel(tester);

      for (final letter in LipLetterDetector.supportedLetters) {
        expect(find.text(letter), findsOneWidget);
      }
    });

    testWidgets('says Matched! when the detection equals the target',
        (tester) async {
      await pumpPanel(
        tester,
        detectedLetter: 'C',
        confidence: 0.8,
        targetLetter: 'C',
      );

      expect(find.text('Matched!'), findsOneWidget);
    });

    testWidgets('stays quiet when the detection differs from the target',
        (tester) async {
      await pumpPanel(
        tester,
        detectedLetter: 'B',
        confidence: 0.8,
        targetLetter: 'C',
      );

      expect(find.text('Matched!'), findsNothing);
    });

    testWidgets('does not say Matched! when no target has been chosen',
        (tester) async {
      // Both the target and the detection are empty here; that is not a match.
      await pumpPanel(tester);

      expect(find.text('Matched!'), findsNothing);
    });

    testWidgets('tapping a chip reports which letter was tapped',
        (tester) async {
      String? tapped;
      await pumpPanel(tester, onLetterTap: (letter) => tapped = letter);

      await tester.tap(find.text('D'));
      await tester.pumpAndSettle();

      expect(tapped, 'D');
    });
  });
}
