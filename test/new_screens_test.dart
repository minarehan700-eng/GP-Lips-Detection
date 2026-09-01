import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/domain/viseme_group.dart';
import 'package:lips_offline/domain/word_challenge.dart';
import 'package:lips_offline/l10n/app_localizations.dart';
import 'package:lips_offline/screens/about_screen.dart';
import 'package:lips_offline/screens/shape_guide_screen.dart';
import 'package:lips_offline/screens/word_library_screen.dart';
import 'package:lips_offline/widgets/app_drawer.dart';

import 'helpers/localized.dart';

void main() {
  late AppLocalizations en;

  setUpAll(() async => en = await translationsFor(const Locale('en')));

  group('shape guide', () {
    testWidgets('shows a card for all five shapes', (tester) async {
      await tester.pumpWidget(localizedApp(const ShapeGuideScreen()));
      await tester.pumpAndSettle();

      // The list is taller than a test window, so each card has to be
      // scrolled to before it can be asserted on.
      for (final group in VisemeGroup.all) {
        await tester.scrollUntilVisible(find.text(group.mouthHint), 200);
        expect(find.text(group.mouthHint), findsOneWidget,
            reason: 'shape ${group.shape} is missing');
      }
    });

    testWidgets('explains why p, b and m share a shape', (tester) async {
      // The single most important thing on the screen: without it a learner
      // reads "B" as the letter B.
      await tester.pumpWidget(localizedApp(const ShapeGuideScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text(en.chartWhySame), 200);

      expect(find.text(en.chartWhySame), findsOneWidget);
    });

    testWidgets('reads each shape as one thing, not as many chips',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(localizedApp(const ShapeGuideScreen()));
      await tester.pumpAndSettle();

      // The neutral shape carries seventeen letters. Spelled out one node at a
      // time, a screen reader would read it as seventeen separate items.
      final neutral = VisemeGroup.forShape('D')!;
      expect(
        find.bySemanticsLabel(RegExp('D: ${neutral.mouthHint}')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('word library', () {
    testWidgets('lists every category and word', (tester) async {
      await tester.pumpWidget(localizedApp(const WordLibraryScreen()));
      await tester.pumpAndSettle();

      for (final category in WordLibrary.categories) {
        await tester.scrollUntilVisible(
          find.text(WordLibraryScreen.categoryName(en, category.id)),
          200,
        );
        expect(
          find.text(WordLibraryScreen.categoryName(en, category.id)),
          findsOneWidget,
        );
      }
    });

    testWidgets('every category has a translated name', (tester) async {
      // A category added without a name would otherwise show its raw id.
      for (final category in WordLibrary.categories) {
        expect(
          WordLibraryScreen.categoryName(en, category.id),
          isNot(category.id),
          reason: 'category "${category.id}" has no translated name',
        );
      }
    });

    testWidgets('tapping a word reports which one', (tester) async {
      String? chosen;

      await tester.pumpWidget(localizedApp(
        WordLibraryScreen(onWordSelected: (w) => chosen = w),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('hello'));
      await tester.pumpAndSettle();

      expect(chosen, 'hello');
    });

    testWidgets('each word says how many shapes it takes', (tester) async {
      await tester.pumpWidget(localizedApp(const WordLibraryScreen()));
      await tester.pumpAndSettle();

      // "hello" is D-E-D-C once the doubled l is collapsed.
      expect(WordChallenge.fromWord('hello')!.length, 4);
      expect(find.text(en.wordShapes(4)), findsWidgets);
    });

    testWidgets('warns that the library is English only', (tester) async {
      await tester.pumpWidget(localizedApp(const WordLibraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text(en.wordEnglishOnly), findsOneWidget);
    });
  });

  group('about', () {
    testWidgets('states the limits as plainly as the abilities',
        (tester) async {
      await tester.pumpWidget(localizedApp(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text(en.aboutCan), findsOneWidget);
      expect(find.text(en.aboutCannot), findsOneWidget);
      expect(find.text(en.aboutPrivacyBody), findsOneWidget);
    });
  });

  group('drawer', () {
    testWidgets('every destination has a translated name', (tester) async {
      for (final destination in AppDestination.values) {
        final label = AppDrawer.labelFor(en, destination);
        expect(label, isNotEmpty, reason: destination.name);
        expect(label, isNot(destination.name),
            reason: '${destination.name} falls through to its raw enum name');
      }
    });

    testWidgets('offers a row for every destination', (tester) async {
      await tester.pumpWidget(localizedApp(
        Scaffold(
          drawer: AppDrawer(
            current: AppDestination.detect,
            onSelected: (_) {},
          ),
          body: const SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();

      // Open it the way a user does.
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      for (final destination in AppDestination.values) {
        expect(find.text(AppDrawer.labelFor(en, destination)), findsOneWidget,
            reason: destination.name);
      }
    });

    testWidgets('choosing a destination reports it and closes', (tester) async {
      AppDestination? chosen;

      await tester.pumpWidget(localizedApp(
        Scaffold(
          drawer: AppDrawer(
            current: AppDestination.detect,
            onSelected: (d) => chosen = d,
          ),
          body: const SizedBox(),
        ),
      ));
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.about));
      await tester.pumpAndSettle();

      expect(chosen, AppDestination.about);
    });

    testWidgets('the current destination is not re-opened', (tester) async {
      var calls = 0;

      await tester.pumpWidget(localizedApp(
        Scaffold(
          drawer: AppDrawer(
            current: AppDestination.detect,
            onSelected: (_) => calls++,
          ),
          body: const SizedBox(),
        ),
      ));
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.homeTitle));
      await tester.pumpAndSettle();

      // Pushing the screen you are already on would stack it on itself.
      expect(calls, 0);
    });
  });
}
