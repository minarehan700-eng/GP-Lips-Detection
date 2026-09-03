import 'package:flutter/material.dart';

import '../application/lip_letter_detector.dart';
import '../core/app_theme.dart';
import '../domain/confusion.dart';
import '../domain/session_record.dart';
import '../infrastructure/practice_history_store.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Shows how practice has been going, letter by letter.
///
/// The point of the screen is the one line at the bottom of the card: which
/// shape to work on next. Everything above it is the evidence for that.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.store});

  /// Injectable so a test does not need the real store.
  final PracticeHistoryStore? store;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final PracticeHistoryStore _store =
      widget.store ?? PracticeHistoryStore();

  List<SessionRecord>? _records;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() => _records = records);
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _store.clear();
    await _reload();
    messenger.showSnackBar(SnackBar(content: Text(l10n.progressCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final records = _records;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l10n.progress)),
      body: GradientBackground(
        child: SafeArea(
          child: records == null
              ? const Center(child: CircularProgressIndicator())
              : records.isEmpty
                  ? _EmptyState(message: l10n.progressNone)
                  : _Report(
                      records: records,
                      onClear: _clear,
                    ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.records, required this.onClear});

  final List<SessionRecord> records;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = PracticeHistoryStore.statsByLetter(
      records,
      LipLetterDetector.supportedLetters,
    );
    final weakest = PracticeHistoryStore.weakestLetter(stats);
    // "You get C wrong" is not actionable. "You make D when you mean C" tells
    // the user their lips are stopping at neutral instead of rounding.
    final confusion =
        ConfusionMatrix.fromRecords(records.confusionAttempts).worst();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.progressRounds(records.length),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          Text(l10n.progressPerLetter,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final stat in stats) ...[
                  _LetterRow(stat: stat),
                  if (stat != stats.last) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          if (weakest != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: AppTheme.brandTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.progressWeakest(weakest.letter),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.confusion, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  confusion == null
                      ? Icons.hourglass_empty_rounded
                      : Icons.compare_arrows_rounded,
                  color: confusion == null ? Colors.white38 : Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    confusion == null
                        ? l10n.confusionNone
                        : l10n.confusionPair(
                            confusion.mistakenFor, confusion.target),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.progressClear),
            ),
          ),
        ],
      ),
    );
  }
}

/// One letter's record: the letter, a bar, and the raw counts.
///
/// The counts are shown as well as the bar because a bar alone cannot
/// distinguish "one out of one" from "nine out of nine".
class _LetterRow extends StatelessWidget {
  const _LetterRow({required this.stat});

  final LetterStat stat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final untried = stat.attempts == 0;

    return Semantics(
      label: untried
          ? '${stat.letter}: ${l10n.progressUntried}'
          : '${stat.letter}: ${l10n.progressAttempts(stat.hits, stat.attempts)}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                stat.letter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stat.accuracy,
                  minHeight: 10,
                  backgroundColor: Colors.white12,
                  color: untried
                      ? Colors.white24
                      : stat.accuracy >= 0.6
                          ? AppTheme.successGreen
                          : Colors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(
                untried
                    ? l10n.progressUntried
                    : l10n.progressAttempts(stat.hits, stat.attempts),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
