import 'dart:async'; // unawaited

import 'package:flutter/material.dart'; // Flutter UI

import '../application/lips_camera_session.dart'; // جلسة الكاميرا
import '../core/app_theme.dart'; // ألوان
import '../widgets/detection_ui.dart'; // بطاقات الحالة
import '../widgets/gradient_background.dart'; // خلفية
import '../widgets/lips_camera_preview.dart'; // معاينة
import '../widgets/lips_detection_panels.dart'; // لوحات الحرف والمقاييس
import 'settings_screen.dart'; // الإعدادات

class HomeScreen extends StatefulWidget { // الشاشة الرئيسية للكشف
  const HomeScreen({super.key}); //

  @override // createState
  State<HomeScreen> createState() => _HomeScreenState(); //
} // نهاية HomeScreen

class _HomeScreenState extends State<HomeScreen> { // حالة الشاشة
  final _session = LipsCameraSession(); // جلسة كاميرا + كشف

  bool _initializing = true; // هل ما زلنا نُهيّئ؟
  bool _setupStarted = false; // هل بدأ الإعداد؟
  String? _targetLetter; // حرف الهدف للتدريب

  @override // initState
  void initState() { //
    super.initState(); //
    _scheduleSetup(); // ابدأ الإعداد بعد أول frame
  } // نهاية initState

  void _scheduleSetup() { // جدولة الإعداد
    if (_setupStarted) return; //
    _setupStarted = true; //
    WidgetsBinding.instance.addPostFrameCallback((_) { // بعد رسم الإطار
      if (!mounted) { //
        _setupStarted = false; //
        return; //
      } //
      unawaited(_setup()); // ابدأ async
    }); //
  } // نهاية _scheduleSetup

  void _notifySessionChanged() { // تحديث الواجهة عند تغيّر الجلسة
    if (mounted) setState(() {}); //
  } // نهاية _notifySessionChanged

  Future<void> _setup() async { // تهيئة الجلسة
    await _session.initialize(_notifySessionChanged); //
    if (!mounted) return; //
    setState(() => _initializing = false); //
  } // نهاية _setup

  Future<void> _openSettings() async { // فتح الإعدادات
    await Navigator.of(context).push( //
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()), //
    ); //
    if (!mounted) return; //
    await _session.applyDetectorSettings(); // أعد تحميل الإعدادات
    _notifySessionChanged(); //
  } // نهاية _openSettings

  Future<void> _retrySetup() async { // إعادة المحاولة بعد خطأ
    _setupStarted = true; //
    setState(() { //
      _initializing = true; //
      _targetLetter = null; //
    }); //
    await _session.reset(_notifySessionChanged); //
    if (!mounted) return; //
    setState(() => _initializing = false); //
  } // نهاية _retrySetup

  void _toggleTargetLetter(String letter) { // تفعيل/إلغاء حرف الهدف
    setState(() { //
      _targetLetter = _targetLetter == letter ? null : letter; //
    }); //
  } // نهاية _toggleTargetLetter

  @override // dispose
  void dispose() { //
    unawaited(_session.dispose()); //
    super.dispose(); //
  } // نهاية dispose

  @override // build
  Widget build(BuildContext context) { //
    return Scaffold( //
      extendBodyBehindAppBar: true, //
      appBar: AppBar( //
        title: const Text('Lips Detection'), //
        actions: [ //
          IconButton( //
            tooltip: 'Settings', //
            onPressed: _openSettings, //
            icon: const Icon(Icons.settings_rounded), //
          ), //
        ], //
      ), //
      body: GradientBackground( //
        child: SafeArea(child: _buildBody(context)), //
      ), //
    ); //
  } // نهاية build

  Widget _buildBody(BuildContext context) { // محتوى الشاشة
    if (_initializing && _session.camera == null && _session.error == null) { //
      return _LoadingView(phase: _session.initPhase); // تحميل
    } //

    if (_session.error != null) { //
      return _ErrorView(error: _session.error!, onRetry: _retrySetup); // خطأ
    } //

    final result = _session.result; //
    final lipsing = result.isLipsing; //

    return Padding( //
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), //
      child: SingleChildScrollView( //
        child: Column( //
          children: [ //
            if (_session.camera != null) //
              LipsCameraPreview( //
                controller: _session.camera!, //
                result: result, //
                frameImageWidth: _session.frameImageWidth, //
                frameImageHeight: _session.frameImageHeight, //
                isFrontCamera: _session.isFrontCamera, //
                lipsing: lipsing, //
              ), //
            if (_session.cameraResolutionLabel != null) ...[ //
              const SizedBox(height: 6), //
              Text( //
                _session.cameraResolutionLabel!, //
                textAlign: TextAlign.center, //
                style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                      color: Colors.white60, //
                    ), //
              ), //
            ], //
            const SizedBox(height: 12), //
            Row( // Face + Lipsing
              children: [ //
                Expanded( //
                  child: DetectionStatusCard( //
                    label: 'Face', //
                    value: result.faceDetected ? 'Detected' : 'Not detected', //
                    accent: result.faceDetected ? AppTheme.brandTeal : Colors.orangeAccent, //
                  ), //
                ), //
                const SizedBox(width: 10), //
                Expanded( //
                  child: DetectionStatusCard( //
                    label: 'Lipsing', //
                    value: lipsing ? 'Yes' : 'No', //
                    accent: lipsing ? const Color(0xFF4ADE80) : Colors.white54, //
                    prominent: true, //
                  ), //
                ), //
              ], //
            ), //
            const SizedBox(height: 10), //
            DetectedLetterPanel( //
              result: result, //
              targetLetter: _targetLetter, //
              onLetterTap: _toggleTargetLetter, //
            ), //
            const SizedBox(height: 10), //
            MouthMetricsPanel(result: result, lipsing: lipsing), //
            const SizedBox(height: 16), //
            Text( // دليل الحروف
              'Smile=E · Round=C · Closed=B · Wide open=A · Slight open=D', //
              textAlign: TextAlign.center, //
              style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                    color: Colors.white60, //
                  ), //
            ), //
          ], //
        ), //
      ), //
    ); //
  } // نهاية _buildBody
} // نهاية _HomeScreenState

class _LoadingView extends StatelessWidget { // شاشة انتظار
  const _LoadingView({required this.phase}); //

  final String phase; //

  @override // build
  Widget build(BuildContext context) { //
    return Center( //
      child: Column( //
        mainAxisAlignment: MainAxisAlignment.center, //
        children: [ //
          const CircularProgressIndicator(), //
          const SizedBox(height: 16), //
          Text( //
            phase, //
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70), //
            textAlign: TextAlign.center, //
          ), //
        ], //
      ), //
    ); //
  } // نهاية build
} // نهاية _LoadingView

class _ErrorView extends StatelessWidget { // شاشة خطأ
  const _ErrorView({required this.error, required this.onRetry}); //

  final String error; //
  final VoidCallback onRetry; //

  @override // build
  Widget build(BuildContext context) { //
    return Center( //
      child: Padding( //
        padding: const EdgeInsets.all(16), //
        child: Column( //
          mainAxisAlignment: MainAxisAlignment.center, //
          children: [ //
            Text( //
              'Initialization failed:\n$error\n\n'
              'Make sure face_landmarker.task exists in '
              'android/app/src/main/assets (and the iOS Runner bundle) '
              'and camera permission is granted.', //
              textAlign: TextAlign.center, //
            ), //
            const SizedBox(height: 16), //
            FilledButton.icon( //
              onPressed: onRetry, //
              icon: const Icon(Icons.refresh_rounded), //
              label: const Text('Try Again'), //
            ), //
          ], //
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية _ErrorView
