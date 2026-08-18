import 'dart:async';

import 'package:flutter/material.dart';

import '../application/lips_camera_session.dart';
import '../core/app_theme.dart';
import '../widgets/detection_ui.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lips_camera_preview.dart';
import '../widgets/lips_detection_panels.dart';
import 'settings_screen.dart';

/// Main detection screen — owns the camera session and displays live results.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _session = LipsCameraSession();

  bool _initializing = true;
  bool _setupStarted = false;
  String? _targetLetter;

  @override
  void initState() {
    super.initState();
    _scheduleSetup();
  }

  /// Defers camera init until after the first frame so the widget tree is ready.
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

  void _notifySessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _setup() async {
    await _session.initialize(_notifySessionChanged);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    await _session.applyDetectorSettings();
    _notifySessionChanged();
  }

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

  void _toggleTargetLetter(String letter) {
    setState(() {
      _targetLetter = _targetLetter == letter ? null : letter;
    });
  }

  @override
  void dispose() {
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

  Widget _buildBody(BuildContext context) {
    if (_initializing && _session.camera == null && _session.error == null) {
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
                    accent: lipsing ? const Color(0xFF4ADE80) : Colors.white54,
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
