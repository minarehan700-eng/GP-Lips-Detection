import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../application/lips_camera_session.dart';
import '../core/app_preferences.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/detection_ui.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lips_camera_preview.dart';
import '../widgets/lips_detection_panels.dart';
import 'settings_screen.dart';

/// The main screen: live camera, lipsing status, and the detected letter.
///
/// Why this screen exists:
/// It is where the user actually practises. It owns a [LipsCameraSession] —
/// which does all the real work — and its own job is only to show whatever the
/// session most recently produced, plus the practice-target letter the user
/// picked.
///
/// The screen has three states: loading, error, and running.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// Owns the camera and both detectors.
  final _session = LipsCameraSession();

  /// True while the camera and model are still starting up.
  bool _initializing = true;

  /// Guards against starting the camera twice.
  bool _setupStarted = false;

  /// The letter the user is practising, or null when no target is set.
  String? _targetLetter;

  /// What was last spoken aloud, so the same thing is not repeated on every
  /// frame — roughly seven a second, which would make a screen reader useless.
  String? _lastAnnouncedLetter;
  bool? _lastAnnouncedFacePresent;
  String? _lastBuzzedMatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleSetup();
  }

  /// Closes the camera when the app leaves the screen and opens it again on
  /// the way back.
  ///
  /// Without this the camera kept streaming while the app was in the
  /// background — the phone's camera indicator stayed lit and the battery
  /// drained — and Android reclaiming the camera left the preview frozen on
  /// return, with no way back except restarting the app.
  ///
  /// Nothing happens while the start-up is still running or an error is on
  /// screen: there is no working camera to close, and reopening would fight
  /// with the "Try Again" button.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_initializing || _session.error != null) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_suspendCamera());
      case AppLifecycleState.resumed:
        unawaited(_resumeCamera());
    }
  }

  Future<void> _suspendCamera() async {
    await _session.suspend();
    _notifySessionChanged();
  }

  Future<void> _resumeCamera() async {
    await _session.resume(_notifySessionChanged);
    _notifySessionChanged();
  }

  /// Starts the camera after the first frame is drawn.
  ///
  /// Opening the camera during `initState` would block the very first build,
  /// so the user would stare at a blank screen. Waiting one frame means the
  /// loading spinner is already visible while the camera warms up.
  void _scheduleSetup() {
    if (_setupStarted) return;
    _setupStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _setupStarted = false;
        return;
      }
      unawaited(_setup());
    });
  }

  /// Speaks a detection to the screen reader and buzzes on a match.
  ///
  /// Why this exists: the detection result only ever appears as text that
  /// never takes focus, so without an explicit announcement a screen-reader
  /// user gets nothing at all. The buzz matters for the same reason in
  /// reverse — someone who cannot hear a chime, and who is looking at their
  /// own face rather than the screen, still feels the phone confirm a match.
  ///
  /// Both are deliberately edge-triggered: they fire when the detection
  /// *changes*, not on every frame.
  void _reportForAccessibility(BuildContext context) {
    final settings = AppPreferencesScope.settingsOf(context);
    final l10n = AppLocalizations.of(context);
    final result = _session.result;

    // sendAnnouncement needs the view the message belongs to, so that on a
    // device showing several Flutter views the speech reaches the right one.
    void say(String message) {
      unawaited(SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ));
    }

    if (settings.announceDetections) {
      if (_lastAnnouncedFacePresent != result.faceDetected) {
        _lastAnnouncedFacePresent = result.faceDetected;
        say(
          result.faceDetected
              ? l10n.a11yAnnounceFaceFound
              : l10n.a11yAnnounceFaceLost,
        );
      }

      final letter = result.detectedLetter;
      if (letter != _lastAnnouncedLetter) {
        _lastAnnouncedLetter = letter;
        if (letter != null) {
          say(l10n.a11yAnnounceLetter(
            letter,
            (result.letterConfidence * 100).round(),
          ));
        }
      }
    }

    final bool matched = _targetLetter != null &&
        result.detectedLetter != null &&
        result.detectedLetter == _targetLetter;
    if (!matched) {
      _lastBuzzedMatch = null;
    } else if (_lastBuzzedMatch != result.detectedLetter) {
      _lastBuzzedMatch = result.detectedLetter;
      if (settings.hapticsEnabled) {
        unawaited(HapticFeedback.mediumImpact());
      }
      if (settings.announceDetections) {
        say(l10n.a11yAnnounceMatched(result.detectedLetter!));
      }
    }
  }

  /// Redraws the screen with the session's latest result.
  ///
  /// This is handed to the session as a callback, so the session never needs
  /// to know anything about widgets. The `mounted` check stops a late frame
  /// from redrawing a screen the user has already left.
  void _notifySessionChanged() {
    if (mounted) setState(() {});
  }

  /// Runs the session start-up and then hides the loading view.
  Future<void> _setup() async {
    await _session.initialize(_notifySessionChanged);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  /// Opens Settings and reloads the thresholds when the user comes back.
  ///
  /// The reload is what makes a moved slider take effect immediately, without
  /// restarting the camera.
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    await _session.applyDetectorSettings();
    _notifySessionChanged();
  }

  /// Restarts the whole camera session after an error ("Try Again" button).
  /// The practice target is cleared so the user starts from a clean screen.
  Future<void> _retrySetup() async {
    _setupStarted = true;
    setState(() {
      _initializing = true;
      _targetLetter = null;
    });
    await _session.reset(_notifySessionChanged);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  /// Sets or clears the practice target when a letter chip is tapped.
  /// Tapping the letter that is already the target switches the target off.
  void _toggleTargetLetter(String letter) {
    setState(() {
      _targetLetter = _targetLetter == letter ? null : letter;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Releases the camera; without this it would keep running in the
    // background and the phone would show the camera-in-use indicator.
    unawaited(_session.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Lips Detection'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  /// Chooses between the loading, error and running views.
  ///
  /// The order matters: the loading view is only shown while there is no
  /// camera and no error yet, so a failure replaces the spinner straight away
  /// instead of leaving the user waiting forever.
  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool stillStartingUp =
        _initializing && _session.camera == null && _session.error == null;
    if (stillStartingUp) {
      return _LoadingView(phase: _session.initPhase);
    }

    if (_session.error != null) {
      return _ErrorView(
        failure: _session.error!,
        detail: _session.errorDetail,
        onRetry: _retrySetup,
      );
    }

    final result = _session.result;
    final lipsing = result.isLipsing;
    _reportForAccessibility(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (_session.camera != null)
              Semantics(
                label: l10n.a11yCameraPreview,
                // The preview is a stream of pixels; describing it once is
                // useful, exposing its internals to a screen reader is not.
                child: ExcludeSemantics(
                  child: LipsCameraPreview(
                controller: _session.camera!,
                result: result,
                frameImageWidth: _session.frameImageWidth,
                frameImageHeight: _session.frameImageHeight,
                    isFrontCamera: _session.isFrontCamera,
                    lipsing: lipsing,
                  ),
                ),
              ),
            if (_session.cameraPreviewSize != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.cameraResolution(
                  _session.cameraPreviewSize!.width.toInt(),
                  _session.cameraPreviewSize!.height.toInt(),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DetectionStatusCard(
                    label: l10n.face,
                    value: result.faceDetected ? l10n.detected : l10n.notDetected,
                    accent: result.faceDetected ? AppTheme.brandTeal : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetectionStatusCard(
                    label: l10n.lipsing,
                    value: lipsing ? l10n.yes : l10n.no,
                    accent: lipsing ? AppTheme.successGreen : Colors.white54,
                    prominent: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DetectedLetterPanel(
              result: result,
              targetLetter: _targetLetter,
              onLetterTap: _toggleTargetLetter,
            ),
            const SizedBox(height: 10),
            MouthMetricsPanel(result: result, lipsing: lipsing),
            const SizedBox(height: 16),
            Text(
              l10n.letterShapeHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spinner shown while starting up, with the current step underneath.
///
/// The step text ("Loading face landmarker...", "Starting camera...") tells
/// the user that the app is working and, if it stops, exactly where it stuck.
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.phase});

  final String phase;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            phase,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shown when the camera or the model could not start.
///
/// It repeats the two causes that account for almost every failure — a missing
/// model file and refused camera permission — so the user can fix the problem
/// without reading the code, and offers a retry button.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.failure,
    required this.detail,
    required this.onRetry,
  });

  final SessionFailure failure;

  /// Raw platform text, used only where there is nothing friendlier to say.
  final String? detail;

  final VoidCallback onRetry;

  /// Turns the failure into wording in the reader's own language.
  String _message(AppLocalizations l10n) {
    switch (failure) {
      case SessionFailure.noCamera:
        return l10n.errorNoCamera;
      case SessionFailure.cameraInit:
        return l10n.errorCameraInit;
      case SessionFailure.landmarker:
        return l10n.errorLandmarkerMissing;
      case SessionFailure.unknown:
        return l10n.errorInitFailed(detail ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _message(l10n),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
