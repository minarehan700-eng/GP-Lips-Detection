import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/lips_camera_session.dart';
import '../core/app_theme.dart';
import '../domain/calibration.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lips_camera_preview.dart';

/// Walks the user through four held poses and measures their face.
///
/// Each step fills as usable frames arrive, so holding still is visibly
/// rewarded and looking away visibly is not — the ring simply stops, which
/// tells the user more than an error at the end would.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with WidgetsBindingObserver {
  final _session = LipsCameraSession();
  final _calibration = Calibration();

  int _stepIndex = 0;
  bool _running = false;
  CalibrationOutcome? _outcome;

  CalibrationStep get _step => CalibrationStep.values[_stepIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_session.initialize(_onFrame));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
    if (!mounted) return;
    if (_running) {
      _calibration.addSample(_step, _session.result);
      if (_calibration.isStepComplete(_step)) {
        _advance();
      }
    }
    setState(() {});
  }

  void _advance() {
    unawaited(HapticFeedback.selectionClick());
    if (_stepIndex < CalibrationStep.values.length - 1) {
      _stepIndex++;
      return;
    }
    _running = false;
    final outcome = _calibration.derive();
    _outcome = outcome;
    if (outcome.accepted) {
      unawaited(_save(outcome));
    }
  }

  Future<void> _save(CalibrationOutcome outcome) async {
    await outcome.settings!.save();
    unawaited(HapticFeedback.mediumImpact());
  }

  void _begin() {
    setState(() {
      _calibration.clear();
      _stepIndex = 0;
      _outcome = null;
      _running = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_session.dispose());
    super.dispose();
  }

  String _promptFor(AppLocalizations l10n, CalibrationStep step) {
    return switch (step) {
      CalibrationStep.rest => l10n.calibrateRest,
      CalibrationStep.wideOpen => l10n.calibrateWideOpen,
      CalibrationStep.rounded => l10n.calibrateRounded,
      CalibrationStep.spread => l10n.calibrateSpread,
    };
  }

  String _problemFor(AppLocalizations l10n, CalibrationProblem problem) {
    return switch (problem) {
      CalibrationProblem.tooFewSamples => l10n.calibrateFailFew,
      CalibrationProblem.noRange => l10n.calibrateFailRange,
      CalibrationProblem.tooRestless => l10n.calibrateFailRestless,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l10n.calibrate)),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
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
                if (_outcome != null)
                  _Result(
                    outcome: _outcome!,
                    message: _outcome!.accepted
                        ? l10n.calibrateSaved
                        : _problemFor(l10n, _outcome!.problem!),
                    onRetry: _begin,
                    retryLabel: l10n.calibrateStart,
                  )
                else if (!_running)
                  _Intro(text: l10n.calibrateIntro, onStart: _begin,
                      startLabel: l10n.calibrateStart)
                else
                  _Step(
                    prompt: _promptFor(l10n, _step),
                    counter: l10n.calibrateStepOf(
                        _stepIndex + 1, CalibrationStep.values.length),
                    progress: _calibration.stepProgress(_step),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro(
      {required this.text, required this.onStart, required this.startLabel});

  final String text;
  final VoidCallback onStart;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(18),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.tune_rounded),
            label: Text(startLabel),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.prompt,
    required this.counter,
    required this.progress,
  });

  final String prompt;
  final String counter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$counter. $prompt',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(counter, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      color: AppTheme.brandTeal,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Text('${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.outcome,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final CalibrationOutcome outcome;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final ok = outcome.accepted;
    return Column(
      children: [
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ok ? Icons.check_circle_outline_rounded : Icons.replay_rounded,
                color: ok ? AppTheme.successGreen : Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.tune_rounded),
            label: Text(retryLabel),
          ),
        ),
      ],
    );
  }
}
