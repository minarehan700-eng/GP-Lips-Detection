import 'package:flutter/material.dart'; // Flutter UI

import '../core/app_theme.dart'; // ألوان
import '../core/detector_settings.dart'; // إعدادات
import '../widgets/glass_card.dart'; // بطاقة
import '../widgets/gradient_background.dart'; // خلفية

class SettingsScreen extends StatefulWidget { // شاشة الإعدادات
  const SettingsScreen({super.key}); //

  @override // createState
  State<SettingsScreen> createState() => _SettingsScreenState(); //
} // نهاية SettingsScreen

class _SettingsScreenState extends State<SettingsScreen> { // حالة الإعدادات
  DetectorSettings _settings = DetectorSettings.defaults; // الإعدادات الحالية
  bool _loading = true; // تحميل من الذاكرة؟

  @override // initState
  void initState() { //
    super.initState(); //
    _load(); //
  } // نهاية initState

  Future<void> _load() async { // تحميل محفوظ
    final loaded = await DetectorSettings.load(); //
    if (!mounted) return; //
    setState(() { //
      _settings = loaded; //
      _loading = false; //
    }); //
  } // نهاية _load

  Future<void> _save() async { // حفظ
    await _settings.save(); //
    if (!mounted) return; //
    ScaffoldMessenger.of(context).showSnackBar( //
      const SnackBar(content: Text('Settings saved')), //
    ); //
  } // نهاية _save

  @override // build
  Widget build(BuildContext context) { //
    return Scaffold( //
      extendBodyBehindAppBar: true, //
      appBar: AppBar( //
        title: const Text('Settings'), //
      ), //
      body: GradientBackground( //
        child: SafeArea( //
          child: _loading //
              ? const Center(child: CircularProgressIndicator()) //
              : SingleChildScrollView( //
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24), //
                  child: Column( //
                    crossAxisAlignment: CrossAxisAlignment.start, //
                    children: [ //
                      Padding( //
                        padding: const EdgeInsets.only(bottom: 16), //
                        child: Text( //
                          'Detector thresholds', //
                          style: Theme.of(context).textTheme.headlineSmall, //
                        ), //
                      ), //
                      GlassCard( //
                        borderRadius: 16, //
                        padding: const EdgeInsets.all(16), //
                        child: Column( //
                          crossAxisAlignment: CrossAxisAlignment.start, //
                          children: [ //
                            _SliderRow( //
                              label: 'Mouth-open threshold', //
                              value: _settings.mouthOpenThreshold, //
                              display: _settings.mouthOpenThreshold.toStringAsFixed(2), //
                              min: 0.05, //
                              max: 0.70, //
                              divisions: 13, //
                              hint: 'Higher = mouth must open more to count as lipsing', //
                              onChanged: (v) => setState( //
                                () => _settings = _settings.copyWith(mouthOpenThreshold: v), //
                              ), //
                            ), //
                            const SizedBox(height: 20), //
                            _SliderRow( //
                              label: 'Motion threshold', //
                              value: _settings.motionThreshold, //
                              display: _settings.motionThreshold.toStringAsFixed(3), //
                              min: 0.010, //
                              max: 0.080, //
                              divisions: 14, //
                              hint: 'Lower = small mouth movement counts as lipsing', //
                              onChanged: (v) => setState( //
                                () => _settings = _settings.copyWith(motionThreshold: v), //
                              ), //
                            ), //
                            const SizedBox(height: 20), //
                            _SliderRow( //
                              label: 'Letter min-score', //
                              value: _settings.letterMinScore, //
                              display: _settings.letterMinScore.toStringAsFixed(2), //
                              min: 0.10, //
                              max: 0.70, //
                              divisions: 12, //
                              hint: 'Higher = stricter A–E classification', //
                              onChanged: (v) => setState( //
                                () => _settings = _settings.copyWith(letterMinScore: v), //
                              ), //
                            ), //
                          ], //
                        ), //
                      ), //
                      const SizedBox(height: 16), //
                      SizedBox( //
                        width: double.infinity, //
                        child: FilledButton.icon( //
                          onPressed: _save, //
                          icon: const Icon(Icons.save_rounded), //
                          label: const Text('Save Settings'), //
                        ), //
                      ), //
                      const SizedBox(height: 12), //
                      SizedBox( //
                        width: double.infinity, //
                        child: OutlinedButton( //
                          onPressed: () => setState(() { //
                            _settings = DetectorSettings.defaults; //
                          }), //
                          child: const Text('Reset to defaults'), //
                        ), //
                      ), //
                    ], //
                  ), //
                ), //
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية _SettingsScreenState

class _SliderRow extends StatelessWidget { // صف slider واحد
  const _SliderRow({ //
    required this.label, //
    required this.value, //
    required this.display, //
    required this.min, //
    required this.max, //
    required this.divisions, //
    required this.hint, //
    required this.onChanged, //
  }); //

  final String label; //
  final double value; //
  final String display; //
  final double min; //
  final double max; //
  final int divisions; //
  final String hint; //
  final ValueChanged<double> onChanged; //

  @override // build
  Widget build(BuildContext context) { //
    return Column( //
      crossAxisAlignment: CrossAxisAlignment.start, //
      children: [ //
        Row( //
          children: [ //
            Expanded( //
              child: Text(label, style: Theme.of(context).textTheme.titleMedium), //
            ), //
            Text( //
              display, //
              style: Theme.of(context).textTheme.bodyLarge?.copyWith( //
                    color: AppTheme.brandTeal, //
                    fontWeight: FontWeight.bold, //
                  ), //
            ), //
          ], //
        ), //
        Slider( //
          value: value.clamp(min, max), //
          min: min, //
          max: max, //
          divisions: divisions, //
          onChanged: onChanged, //
        ), //
        Text( //
          hint, //
          style: Theme.of(context).textTheme.labelSmall?.copyWith( //
                color: Colors.white60, //
              ), //
        ), //
      ], //
    ); //
  } // نهاية build
} // نهاية _SliderRow
