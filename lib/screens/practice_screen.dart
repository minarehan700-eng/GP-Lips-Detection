import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../application/lip_letter_detector.dart';
import '../application/lips_camera_session.dart';
import '../core/app_preferences.dart';
import '../core/app_theme.dart';
import '../domain/practice_session.dart';
import '../domain/session_record.dart';
import '../infrastructure/practice_history_store.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lips_camera_preview.dart';

/// A guided round: the app names a letter, the user holds that mouth shape,
/// the app scores it and moves on.
///
/// Why this exists alongside the home screen:
/// the home screen answers "what shape am I making?". That is a demonstration.
/// This answers "am I getting better?", which is what someone actually
/// practising needs, and it is the only place a result is written down.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.letters});

  /// The letters to run through, defaulting to all of them shuffled.
  final List<String>? letters;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with WidgetsBindingObserver {
  final _session = LipsCameraSession();
  final _history = PracticeHistoryStore();

  late PracticeSession _round;

  bool _initializing = true;
  bool _saved = false;
  PracticePhase _lastPhase = PracticePhase.waiting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _round = PracticeSession(targets: _buildTargets())..start(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_setup());
    });
  }

  /// Every letter, in a different order each round.
  ///
  /// Shuffled on purpose: in a fixed order people learn the sequence rather
  /// than the shapes, and start making the next shape before it is asked for.
  List<String> _buildTargets() {
    final letters = [...?widget.letters];
    if (letters.isEmpty) {
      letters.addAll(LipLetterDetector.supportedLetters);
      letters.shuffle();
    }
    return letters;
  }

  Future<void> _setup() async {
    await _session.initialize(_onFrame);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_initializing || _session.error != null) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_session.resume(_onFrame).then((_) => _refresh()));
    } else {
      unawaited(_session.suspend().then((_) => _refresh()));
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Feeds each detection into the round and reacts to what it decides.
  void _onFrame() {
    if (!mounted) return;
    final phase = _round.update(_session.result, DateTime.now());
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _onPhaseChanged(phase);
    }
    if (_round.isFinished && !_saved) {
      _saved = true;
      unawaited(_saveRound());
    }
    setState(() {});
  }

  /// Confirms an outcome by vibration and by speech, for the same reason the
  /// home screen does: the user is looking at their own face, not the screen,
  /// and may not hear a sound at all.
  void _onPhaseChanged(PracticePhase phase) {
    final settings = AppPreferencesScope.settingsOf(context);
    final l10n = AppLocalizations.of(context);
    final letter = _round.attempts.isEmpty ? null : _round.attempts.last.letter;

    void say(String message) {
      unawaited(SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ));
    }

    switch (phase) {
      case PracticePhase.confirmed:
      case PracticePhase.finished:
        if (letter != null && _round.attempts.last.succeeded) {
          if (settings.hapticsEnabled) unawaited(HapticFeedback.mediumImpact());
          if (settings.announceDetections) say(l10n.a11yPracticeHeld(letter));
        }
      case PracticePhase.missed:
        if (letter != null) {
          if (settings.hapticsEnabled) unawaited(HapticFeedback.lightImpact());
          if (settings.announceDetections) say(l10n.a11yPracticeMissed(letter));
        }
      case PracticePhase.waiting:
        final target = _round.currentTarget;
        if (target != null && settings.announceDetections) {
          say(l10n.a11yPracticeTarget(target));
        }
      case PracticePhase.holding:
        break;
    }
  }

  Future<void> _saveRound() async {
    await _history.add(
      SessionRecord.fromAttempts(_round.attempts, DateTime.now()),
    );
  }

  void _restart() {
    setState(() {
      _round = PracticeSession(targets: _buildTargets())..start(DateTime.now());
      _saved = false;
      _lastPhase = PracticePhase.waiting;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_session.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l10n.practice)),
      body: GradientBackground(
        child: SafeArea(child: _buildBody(context, l10n)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_initializing && _session.camera == null && _session.error == null) {
      return Center(child: Text(_session.initPhase));
    }
    if (_session.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.errorCameraInit, textAlign: TextAlign.center),
        ),
      );
    }
    if (_round.isFinished) {
      return _RoundSummary(round: _round, onAgain: _restart);
    }

    final now = DateTime.now();
    final target = _round.currentTarget!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Column(
        children: [
          if (_session.camera != null)
            ExcludeSemantics(
              child: LipsCameraPreview(
                controller: _session.camera!,
                result: _session.result,
                frameImageWidth: _session.frameImageWidth,
                frameImageHeight: _session.frameImageHeight,
                isFrontCamera: _session.isFrontCamera,
                lipsing: _session.result.isLipsing,
              ),
            ),
          const SizedBox(height: 14),
          Text(
            l10n.practiceProgress(_round.completedCount, _round.totalCount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            label: l10n.a11yPracticeTarget(target),
            child: ExcludeSemantics(
              child: _TargetRing(
                letter: target,
                holdProgress: _round.holdProgress(now),
                timeRemaining: _round.timeRemaining(now),
                holding: _round.phase == PracticePhase.holding,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            switch (_round.phase) {
              PracticePhase.holding => l10n.practiceHold,
              PracticePhase.confirmed => l10n.practiceGotIt,
              PracticePhase.missed => l10n.practiceMissed,
              _ => l10n.practiceMakeShape,
            },
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// The big letter with a ring that fills while the shape is held.
///
/// Two things are shown at once: how much of the hold is done (the ring), and
/// how much of the time limit is left (the colour draining from the track).
class _TargetRing extends StatelessWidget {
  const _TargetRing({
    required this.letter,
    required this.holdProgress,
    required this.timeRemaining,
    required this.holding,
  });

  final String letter;
  final double holdProgress;
  final double timeRemaining;
  final bool holding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: timeRemaining,
              strokeWidth: 4,
              color: Colors.white24,
            ),
          ),
          SizedBox(
            width: 148,
            height: 148,
            child: CircularProgressIndicator(
              value: holdProgress,
              strokeWidth: 8,
              color: holding ? AppTheme.successGreen : AppTheme.brandTeal,
            ),
          ),
          Text(
            letter,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: holding ? AppTheme.successGreen : Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

/// What the user sees when the round ends.
class _RoundSummary extends StatelessWidget {
  const _RoundSummary({required this.round, required this.onAgain});

  final PracticeSession round;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final record = SessionRecord.fromAttempts(round.attempts, DateTime.now());

    // A miss that scored well is worth calling out separately from one that
    // was nowhere near: it tells the user they nearly had it.
    final nearMiss = round.attempts
        .where((a) => !a.succeeded && a.bestConfidence >= 0.20)
        .toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.practiceDone,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l10n.practiceScore(record.hits, record.total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.practiceBestStreak(record.bestStreak)),
                  if (nearMiss.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.practiceNearMiss(nearMiss.first.letter),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.brandTeal,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAgain,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.practiceAgain),
            ),
          ],
        ),
      ),
    );
  }
}
