import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../domain/viseme_group.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// A reference chart for the five mouth shapes.
///
/// This is the screen that teaches the idea the whole app rests on: a shape is
/// not a letter, it is every letter that looks the same on the lips. A learner
/// who understands that can use the app properly. One who thinks "B" means the
/// letter B has been actively misled.
class ShapeGuideScreen extends StatelessWidget {
  const ShapeGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l10n.chart)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              Text(
                l10n.chartIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              for (final group in VisemeGroup.all) ...[
                _ShapeCard(group: group),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: AppTheme.brandTeal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.chartWhySame,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.chartWhySameBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One shape: its code, what the mouth is doing, the letters it covers, and
/// words to feel it with.
class _ShapeCard extends StatelessWidget {
  const _ShapeCard({required this.group});

  final VisemeGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      // Read as one thing. Letter by letter, a screen reader would spell out
      // seventeen separate chips for the neutral shape.
      label: '${group.shape}: ${group.mouthHint}. '
          '${l10n.chartLetters}: ${group.letters.join(", ")}.',
      child: ExcludeSemantics(
        child: GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShapeBadge(shape: group.shape),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.mouthHint, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    Text(
                      l10n.chartLetters,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final letter in group.letters)
                          _LetterPill(letter: letter),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.chartTry}: ${group.exampleWords.join(" · ")}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.brandTeal),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeBadge extends StatelessWidget {
  const _ShapeBadge({required this.shape});

  final String shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.brandTeal, AppTheme.brandBlue],
        ),
      ),
      child: Text(
        shape,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _LetterPill extends StatelessWidget {
  const _LetterPill({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        letter,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
