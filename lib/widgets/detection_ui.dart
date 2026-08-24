import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'glass_card.dart';

/// A small card showing one status: a label on top, a coloured value below.
///
/// Used for the "Face: Detected" and "Lipsing: Yes" cards. The colour is
/// passed in by the screen so the same card can turn green, teal or grey
/// depending on what it is reporting.
class DetectionStatusCard extends StatelessWidget {
  const DetectionStatusCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.prominent = false,
  });

  /// The small caption, e.g. "Lipsing".
  final String label;

  /// The value shown underneath, e.g. "Yes".
  final String value;

  /// Colour of the value text, chosen by the caller to signal state.
  final Color accent;

  /// When true the value is printed larger — used for the Lipsing card,
  /// which is the single most important thing on the screen.
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: (prominent
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable A–E button under the detected letter.
///
/// A chip can be in three states at once, which is why it takes two flags:
///   * [active] — the app is detecting this letter right now (teal);
///   * [target] — the user chose this letter to practise (blue);
///   * neither  — a plain, dim chip.
///
/// [active] is checked first, so seeing your own mouth match is what stands
/// out most.
class LetterChip extends StatelessWidget {
  const LetterChip({
    super.key,
    required this.letter,
    required this.active,
    required this.onTap,
    this.target = false,
  });

  /// The letter drawn on the chip, e.g. "C".
  final String letter;

  /// True when this letter is currently being detected.
  final bool active;

  /// True when the user picked this letter as a practice target.
  final bool target;

  /// Called when the chip is tapped, to set or clear the target.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = target
        ? AppTheme.brandBlue
        : active
            ? AppTheme.brandTeal
            : Colors.white24;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.brandTeal.withValues(alpha: 0.25)
              : target
                  ? AppTheme.brandBlue.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: active || target ? 1.5 : 1,
          ),
        ),
        child: Text(
          letter,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: active
                    ? AppTheme.brandTeal
                    : target
                        ? AppTheme.brandBlue
                        : Colors.white54,
                fontWeight: active || target ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

/// A small tile showing one mouth measurement as a percentage.
///
/// These tiles let the user (and an examiner) see the raw MediaPipe numbers
/// behind a decision, instead of only the final letter.
class MouthMetricTile extends StatelessWidget {
  const MouthMetricTile({super.key, required this.label, required this.value});

  /// Name of the measurement, e.g. "Pucker".
  final String label;

  /// The measurement as a whole percentage from 0 to 100.
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('$value%', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
