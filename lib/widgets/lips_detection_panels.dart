import 'package:flutter/material.dart'; // Flutter UI
import 'package:flutter_animate/flutter_animate.dart'; // حركات fade

import '../application/lip_letter_detector.dart'; // الحروف المدعومة
import '../core/app_theme.dart'; // ألوان
import '../domain/face_lips_result.dart'; // نتيجة الكشف
import 'detection_ui.dart'; // LetterChip وغيرها
import 'glass_card.dart'; // بطاقة زجاجية

class DetectedLetterPanel extends StatelessWidget { // لوحة الحرف المكتشف
  const DetectedLetterPanel({ // مُنشئ
    super.key, //
    required this.result, // نتيجة الكشف
    required this.targetLetter, // حرف الهدف للتدريب
    required this.onLetterTap, // عند الضغط على chip
  }); //

  final FaceLipsResult result; //
  final String? targetLetter; //
  final ValueChanged<String> onLetterTap; //

  @override // build
  Widget build(BuildContext context) { //
    final displayLetter = result.detectedLetter; // الحرف المعروض
    final matched = targetLetter != null && displayLetter == targetLetter; // هل طابق الهدف؟

    return GlassCard( //
      borderRadius: 16, //
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), //
      child: Column( //
        children: [ //
          Text( // عنوان
            'Detected letter', //
            style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                  color: Colors.white70, //
                ), //
          ), //
          const SizedBox(height: 6), //
          Text( // الحرف الكبير
            displayLetter ?? '—', //
            style: Theme.of(context).textTheme.displayMedium?.copyWith( //
                  color: matched //
                      ? const Color(0xFF4ADE80) // أخضر عند التطابق
                      : displayLetter != null //
                          ? AppTheme.brandTeal //
                          : Colors.white38, //
                  fontWeight: FontWeight.w800, //
                  letterSpacing: 2, //
                ), //
          ), //
          if (displayLetter != null) ...[ // إذا يوجد حرف
            const SizedBox(height: 2), //
            Text( // نسبة الثقة
              '${(result.letterConfidence * 100).round()}% confidence', //
              style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                    color: Colors.white54, //
                  ), //
            ), //
          ], //
          if (matched) ...[ // رسالة تطابق
            const SizedBox(height: 4), //
            Text( //
              'Matched!', //
              style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                    color: const Color(0xFF4ADE80), //
                    fontWeight: FontWeight.w600, //
                  ), //
            ), //
          ], //
          const SizedBox(height: 12), //
          Row( // صف chips A-E
            mainAxisAlignment: MainAxisAlignment.center, //
            children: [ //
              for (final letter in LipLetterDetector.supportedLetters) ...[ //
                LetterChip( //
                  letter: letter, //
                  active: displayLetter == letter, //
                  target: targetLetter == letter, //
                  onTap: () => onLetterTap(letter), //
                ), //
                if (letter != LipLetterDetector.supportedLetters.last) //
                  const SizedBox(width: 8), //
              ], //
            ], //
          ), //
        ], //
      ), //
    ).animate().fadeIn(delay: 40.ms); // ظهور تدريجي
  } // نهاية build
} // نهاية DetectedLetterPanel

class MouthMetricsPanel extends StatelessWidget { // لوحة مقاييس الفم
  const MouthMetricsPanel({ // مُنشئ
    super.key, //
    required this.result, //
    required this.lipsing, //
  }); //

  final FaceLipsResult result; //
  final bool lipsing; //

  @override // build
  Widget build(BuildContext context) { //
    final mouthPct = (result.mouthOpen.clamp(0.0, 1.0) * 100).round(); // % فتح الفم

    return GlassCard( //
      borderRadius: 16, //
      padding: const EdgeInsets.all(12), //
      child: Column( //
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [ //
          Row( // صف العنوان والنسبة
            mainAxisAlignment: MainAxisAlignment.spaceBetween, //
            children: [ //
              Text('Mouth open', style: Theme.of(context).textTheme.titleSmall), //
              Text( //
                '$mouthPct%', //
                style: Theme.of(context).textTheme.titleSmall?.copyWith( //
                      color: AppTheme.brandTeal, //
                      fontWeight: FontWeight.w600, //
                    ), //
              ), //
            ], //
          ), //
          const SizedBox(height: 8), //
          ClipRRect( // شريط تقدم
            borderRadius: BorderRadius.circular(8), //
            child: LinearProgressIndicator( //
              value: result.mouthOpen.clamp(0.0, 1.0), //
              minHeight: 8, //
              backgroundColor: Colors.white12, //
              color: lipsing ? const Color(0xFF4ADE80) : AppTheme.brandBlue, //
            ), //
          ), //
          const SizedBox(height: 10), //
          Row( // pucker و smile
            children: [ //
              MouthMetricTile( //
                label: 'Pucker', //
                value: (result.mouthPucker * 100).round(), //
              ), //
              const SizedBox(width: 10), //
              MouthMetricTile( //
                label: 'Smile', //
                value: (result.smile * 100).round(), //
              ), //
            ], //
          ), //
          const SizedBox(height: 8), //
          Row( // close, funnel, stretch
            children: [ //
              MouthMetricTile( //
                label: 'Close', //
                value: (result.mouthClose * 100).round(), //
              ), //
              const SizedBox(width: 10), //
              MouthMetricTile( //
                label: 'Funnel', //
                value: (result.mouthFunnel * 100).round(), //
              ), //
              const SizedBox(width: 10), //
              MouthMetricTile( //
                label: 'Stretch', //
                value: (result.mouthStretch * 100).round(), //
              ), //
            ], //
          ), //
        ], //
      ), //
    ).animate().fadeIn(delay: 80.ms); //
  } // نهاية build
} // نهاية MouthMetricsPanel
