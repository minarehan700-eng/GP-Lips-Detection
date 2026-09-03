import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/domain/session_record.dart';
import 'package:lips_offline/infrastructure/practice_history_store.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized.dart';

/// Tests for the screen that reports how practice is going.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async => en = await translationsFor(const Locale('en')));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SessionRecord recordOf(List<(String, bool)> results) => SessionRecord(
        finishedAt: DateTime(2026, 1, 1),
        results: [
          for (final (letter, ok) in results)
            (
              letter: letter,
              succeeded: ok,
              bestConfidence: 0.5,
              confusedWith: null,
            ),
        ],
        totalMilliseconds: 1000,
      );

  Future<void> pumpProgress(WidgetTester tester,
      {List<SessionRecord> seed = const []}) async {
    final store = PracticeHistoryStore();
    for (final record in seed) {
      await store.add(record);
    }
    await tester.pumpWidget(localizedApp(ProgressScreen(store: store)));
    await tester.pumpAndSettle();
  }

  testWidgets('says so when nothing has been practised', (tester) async {
    await pumpProgress(tester);

    expect(find.text(en.progressNone), findsOneWidget);
  });

  testWidgets('shows a row for every letter, tried or not', (tester) async {
    await pumpProgress(tester, seed: [recordOf([('A', true)])]);

    // Untried letters still get a row: seeing that C has never been attempted
    // is itself useful.
    expect(find.text(en.progressUntried), findsWidgets);
    expect(find.text(en.progressAttempts(1, 1)), findsOneWidget);
  });

  testWidgets('counts add up across several rounds', (tester) async {
    await pumpProgress(tester, seed: [
      recordOf([('A', true), ('A', false)]),
      recordOf([('A', true)]),
    ]);

    expect(find.text(en.progressAttempts(2, 3)), findsOneWidget);
  });

  testWidgets('names the letter worth working on', (tester) async {
    await pumpProgress(tester, seed: [
      recordOf([('A', true), ('A', true), ('A', true)]),
      recordOf([('B', false), ('B', false), ('B', false)]),
    ]);

    expect(find.text(en.progressWeakest('B')), findsOneWidget);
  });

  testWidgets('gives no advice until a letter has been tried enough',
      (tester) async {
    await pumpProgress(tester, seed: [recordOf([('A', false)])]);

    // One unlucky attempt is not evidence of a weakness.
    expect(find.text(en.progressWeakest('A')), findsNothing);
  });

  testWidgets('reports how many rounds are stored', (tester) async {
    await pumpProgress(tester, seed: [
      recordOf([('A', true)]),
      recordOf([('B', true)]),
    ]);

    expect(find.text(en.progressRounds(2)), findsOneWidget);
  });

  testWidgets('clearing empties the screen and confirms', (tester) async {
    await pumpProgress(tester, seed: [recordOf([('A', true)])]);

    final button = find.text(en.progressClear);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text(en.progressCleared), findsOneWidget);
    expect(find.text(en.progressNone), findsOneWidget);
  });

  testWidgets('each letter row is readable by a screen reader',
      (tester) async {
    final handle = tester.ensureSemantics();

    await pumpProgress(tester, seed: [recordOf([('A', true), ('A', false)])]);

    // The bar carries the meaning visually; without a label the row is silent.
    expect(
      find.bySemanticsLabel('A: ${en.progressAttempts(1, 2)}'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('names the pair the user keeps mixing up', (tester) async {
    // "You get C wrong" is not actionable. This is.
    final store = PracticeHistoryStore();
    await store.add(SessionRecord(
      finishedAt: DateTime(2026, 1, 1),
      results: [
        for (var i = 0; i < 4; i++)
          (letter: 'C', succeeded: false, bestConfidence: 0.2, confusedWith: 'D'),
      ],
      totalMilliseconds: 4000,
    ));

    await tester.pumpWidget(localizedApp(ProgressScreen(store: store)));
    await tester.pumpAndSettle();

    final finder = find.text(en.confusionPair('D', 'C'));
    await tester.scrollUntilVisible(finder, 200);
    expect(finder, findsOneWidget);
  });

  testWidgets('says nothing when there is no clear pattern', (tester) async {
    final store = PracticeHistoryStore();
    await store.add(SessionRecord(
      finishedAt: DateTime(2026, 1, 1),
      results: const [
        (letter: 'C', succeeded: false, bestConfidence: 0.2, confusedWith: 'D'),
      ],
      totalMilliseconds: 1000,
    ));

    await tester.pumpWidget(localizedApp(ProgressScreen(store: store)));
    await tester.pumpAndSettle();

    final finder = find.text(en.confusionNone);
    await tester.scrollUntilVisible(finder, 200);
    expect(finder, findsOneWidget);
  });

  testWidgets('the screen works in Arabic', (tester) async {
    final ar = await translationsFor(const Locale('ar'));
    final store = PracticeHistoryStore();
    await store.add(recordOf([('A', true)]));

    await tester.pumpWidget(localizedApp(
      ProgressScreen(store: store),
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ar.progressPerLetter), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(ProgressScreen))),
      TextDirection.rtl,
    );
  });
}
