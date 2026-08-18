import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'glass_card.dart';

class DetectionStatusCard extends StatelessWidget {
  const DetectionStatusCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.prominent = false,
  });

  final String label;
  final String value;
  final Color accent;
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

class LetterChip extends StatelessWidget {
  const LetterChip({
    super.key,
    required this.letter,
    required this.active,
    required this.onTap,
    this.target = false,
  });

  final String letter;
  final bool active;
  final bool target;
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

class MouthMetricTile extends StatelessWidget {
  const MouthMetricTile({super.key, required this.label, required this.value});

  final String label;
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
