import 'dart:async';

import 'package:flutter/material.dart';

import '../application/lips_camera_session.dart';
import '../core/app_theme.dart';
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
    final bool stillStartingUp =
        _initializing && _session.camera == null && _session.error == null;
    if (stillStartingUp) {
      return _LoadingView(phase: _session.initPhase);
    }

    if (_session.error != null) {
      return _ErrorView(error: _session.error!, onRetry: _retrySetup);
    }

    final result = _session.result;
    final lipsing = result.isLipsing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (_session.camera != null)
              LipsCameraPreview(
                controller: _session.camera!,
                result: result,
                frameImageWidth: _session.frameImageWidth,
                frameImageHeight: _session.frameImageHeight,
                isFrontCamera: _session.isFrontCamera,
                lipsing: lipsing,
              ),
            if (_session.cameraResolutionLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                _session.cameraResolutionLabel!,
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
                    label: 'Face',
                    value: result.faceDetected ? 'Detected' : 'Not detected',
                    accent: result.faceDetected ? AppTheme.brandTeal : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetectionStatusCard(
                    label: 'Lipsing',
                    value: lipsing ? 'Yes' : 'No',
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
              'Smile=E · Round=C · Closed=B · Wide open=A · Slight open=D',
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
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Initialization failed:\n$error\n\n'
              'Make sure face_landmarker.task exists in '
              'android/app/src/main/assets (and the iOS Runner bundle) '
              'and camera permission is granted.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
