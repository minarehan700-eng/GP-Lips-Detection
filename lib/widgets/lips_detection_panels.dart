import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../application/lip_letter_detector.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../domain/face_lips_result.dart';
import 'detection_ui.dart';
import 'glass_card.dart';

/// The big detected letter, its confidence, and the A–E practice chips.
///
/// This is the panel the user watches while practising: it shows what the app
/// currently reads, and whether that equals the letter they are aiming for.
class DetectedLetterPanel extends StatelessWidget {
  const DetectedLetterPanel({
    super.key,
    required this.result,
    required this.targetLetter,
    required this.onLetterTap,
  });

  /// The latest detection result.
  final FaceLipsResult result;

  /// The letter the user is practising, or null when none is chosen.
  final String? targetLetter;

  /// Called with the tapped letter so the screen can set or clear the target.
  final ValueChanged<String> onLetterTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayLetter = result.detectedLetter;

    // "Matched!" only makes sense when a target has actually been chosen —
    // without the null check, two blank values would count as a match.
    final matched = targetLetter != null && displayLetter == targetLetter;

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        children: [
          Text(
            l10n.detectedLetter,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            displayLetter ?? '—',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: matched
                      ? AppTheme.successGreen
                      : displayLetter != null
                          ? AppTheme.brandTeal
                          : Colors.white38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
          ),
          if (displayLetter != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.confidencePercent((result.letterConfidence * 100).round()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
          if (matched) ...[
            const SizedBox(height: 4),
            Text(
              l10n.matched,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final letter in LipLetterDetector.supportedLetters) ...[
                LetterChip(
                  letter: letter,
                  active: displayLetter == letter,
                  target: targetLetter == letter,
                  onTap: () => onLetterTap(letter),
                ),
                if (letter != LipLetterDetector.supportedLetters.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 40.ms);
  }
}

/// The raw mouth numbers: an open-mouth bar plus five smaller tiles.
///
/// Every value here comes straight from MediaPipe, converted from 0.0–1.0 into
/// a percentage. Showing them makes the app's decisions explainable: if the
/// letter looks wrong, these numbers say why.
class MouthMetricsPanel extends StatelessWidget {
  const MouthMetricsPanel({
    super.key,
    required this.result,
    required this.lipsing,
  });

  /// The latest detection result.
  final FaceLipsResult result;

  /// True when lipsing is detected; turns the progress bar green.
  final bool lipsing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Clamped before scaling so an out-of-range value can never print
    // something like "132%".
    final mouthPct = (result.mouthOpen.clamp(0.0, 1.0) * 100).round();

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.mouthOpen, style: Theme.of(context).textTheme.titleSmall),
              Text(
                l10n.percentValue(mouthPct),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.brandTeal,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: result.mouthOpen.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: lipsing ? AppTheme.successGreen : AppTheme.brandBlue,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              MouthMetricTile(
                label: l10n.pucker,
                value: (result.mouthPucker * 100).round(),
              ),
              const SizedBox(width: 10),
              MouthMetricTile(
                label: l10n.smile,
                value: (result.smile * 100).round(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              MouthMetricTile(
                label: l10n.closeShape,
                value: (result.mouthClose * 100).round(),
              ),
              const SizedBox(width: 10),
              MouthMetricTile(
                label: l10n.funnel,
                value: (result.mouthFunnel * 100).round(),
              ),
              const SizedBox(width: 10),
              MouthMetricTile(
                label: l10n.stretch,
                value: (result.mouthStretch * 100).round(),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 80.ms);
  }
}
