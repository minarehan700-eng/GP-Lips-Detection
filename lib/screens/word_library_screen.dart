import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../domain/word_challenge.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Browse the words available to practise, grouped by what they are for.
///
/// Grouped rather than listed alphabetically: somebody opens this screen
/// because they want to be able to say something in particular, and
/// "emergency" is a more useful way in than "starts with H".
class WordLibraryScreen extends StatelessWidget {
  const WordLibraryScreen({super.key, this.onWordSelected});

  /// Called with the chosen word. Left injectable so the list can be tested
  /// without opening a camera screen.
  final void Function(String word)? onWordSelected;

  /// The translated name for a category id.
  static String categoryName(AppLocalizations l10n, String id) {
    return switch (id) {
      'greetings' => l10n.wordsGreetings,
      'numbers' => l10n.wordsNumbers,
      'emergency' => l10n.wordsEmergency,
      'everyday' => l10n.wordsEveryday,
      _ => id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l10n.words)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              Text(l10n.wordsIntro,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text(
                l10n.wordEnglishOnly,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.orangeAccent),
              ),
              const SizedBox(height: 18),
              for (final category in WordLibrary.categories) ...[
                Text(
                  categoryName(l10n, category.id),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final word in category.words)
                        _WordChip(
                          word: word,
                          onTap: onWordSelected == null
                              ? null
                              : () => onWordSelected!(word),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One word, with how many shapes it takes to say — which is the honest
/// measure of how hard it will be.
class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, this.onTap});

  final String word;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final challenge = WordChallenge.fromWord(word);
    final shapes = challenge?.length ?? 0;

    return Semantics(
      button: onTap != null,
      label: '$word, ${l10n.wordShapes(shapes)}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.wordShapes(shapes),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.brandTeal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
