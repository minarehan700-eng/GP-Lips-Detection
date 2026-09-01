import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../application/lips_camera_session.dart';
import '../core/app_preferences.dart';
import '../core/app_theme.dart';
import '../domain/word_challenge.dart';
import '../domain/word_session.dart';
import '../l10n/app_localizations.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lips_camera_preview.dart';

/// Mouth one word, shape by shape.
///
/// The screen shows the whole run of shapes at once, with the current one
/// picked out. Seeing what is coming is part of the exercise: a lip reader
/// works from the rhythm of a word, not from one frozen shape.
class WordPracticeScreen extends StatefulWidget {
  const WordPracticeScreen({super.key, required this.word});

  final String word;

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen>
    with WidgetsBindingObserver {
  final _session = LipsCameraSession();

  WordSession? _word;
  bool _initializing = true;
  WordPhase _lastPhase = WordPhase.waiting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final challenge = WordChallenge.fromWord(widget.word);
    if (challenge != null) {
      _word = WordSession(challenge: challenge)..start(DateTime.now());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_setup());
    });
  }

  Future<void> _setup() async {
    await _session.initialize(_onFrame);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_initializing || _session.error != null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_session.resume(_onFrame).then((_) => _refresh()));
    } else {
      unawaited(_session.suspend().then((_) => _refresh()));
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onFrame() {
    final word = _word;
    if (!mounted || word == null) return;

    final phase = word.update(_session.result, DateTime.now());
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _announce(phase, word);
    }
    setState(() {});
  }

  /// Confirms each shape by touch and by speech, for the same reason every
  /// other screen does: the user is watching their own mouth, not the phone.
  void _announce(WordPhase phase, WordSession word) {
    final settings = AppPreferencesScope.settingsOf(context);
    final l10n = AppLocalizations.of(context);

    void say(String message) {
      if (!settings.announceDetections) return;
      unawaited(SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ));
    }

    switch (phase) {
      case WordPhase.complete:
        if (settings.hapticsEnabled) unawaited(HapticFeedback.mediumImpact());
        say(l10n.wordComplete);
      case WordPhase.waiting:
        final shape = word.currentShape;
        if (shape != null && word.completedShapes > 0) {
          if (settings.hapticsEnabled) unawaited(HapticFeedback.selectionClick());
          say(l10n.a11yWordShape(
            word.completedShapes + 1,
            word.challenge.length,
            shape,
          ));
        }
      case WordPhase.expired:
        say(l10n.wordExpired);
      case WordPhase.holding:
        break;
    }
  }

  void _restart() {
    setState(() {
      _word?.start(DateTime.now());
      _lastPhase = WordPhase.waiting;
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
    final word = _word;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(widget.word)),
      body: GradientBackground(
        child: SafeArea(
          child: word == null
              ? Center(child: Text(l10n.wordExpired))
              : _buildBody(context, l10n, word),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppLocalizations l10n, WordSession word) {
    if (_session.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.errorCameraInit, textAlign: TextAlign.center),
        ),
      );
    }

    final done = word.isComplete;
    final expired = word.phase == WordPhase.expired;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
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
          const SizedBox(height: 16),
          Text(
            done
                ? l10n.wordComplete
                : expired
                    ? l10n.wordExpired
                    : l10n.wordSayIt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: done ? AppTheme.successGreen : null,
                ),
          ),
          const SizedBox(height: 14),
          _ShapeTrack(word: word),
          const SizedBox(height: 18),
          if (done || expired)
            FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.practiceAgain),
            )
          else
            LinearProgressIndicator(
              value: word.timeRemaining(DateTime.now()),
              backgroundColor: Colors.white10,
              color: Colors.white24,
            ),
        ],
      ),
    );
  }
}

/// The whole run of shapes, with the current one picked out.
class _ShapeTrack extends StatelessWidget {
  const _ShapeTrack({required this.word});

  final WordSession word;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shapes = word.challenge.shapes;

    return Semantics(
      liveRegion: true,
      label: word.currentShape == null
          ? l10n.wordComplete
          : l10n.a11yWordShape(
              word.completedShapes + 1, shapes.length, word.currentShape!),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < shapes.length; i++)
              _ShapeStep(
                shape: shapes[i],
                done: i < word.completedShapes,
                current: i == word.completedShapes,
                holdProgress: i == word.completedShapes
                    ? word.holdProgress(DateTime.now())
                    : 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShapeStep extends StatelessWidget {
  const _ShapeStep({
    required this.shape,
    required this.done,
    required this.current,
    required this.holdProgress,
  });

  final String shape;
  final bool done;
  final bool current;
  final double holdProgress;

  @override
  Widget build(BuildContext context) {
    final colour = done
        ? AppTheme.successGreen
        : current
            ? AppTheme.brandTeal
            : Colors.white24;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (current)
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: holdProgress,
                strokeWidth: 3,
                color: AppTheme.successGreen,
              ),
            ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colour.withValues(alpha: done || current ? 0.22 : 0.06),
              border: Border.all(color: colour, width: current ? 2 : 1),
            ),
            child: Text(
              shape,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: done || current ? colour : Colors.white38,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
