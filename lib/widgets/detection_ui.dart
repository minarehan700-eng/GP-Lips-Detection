import 'package:flutter/material.dart'; // Flutter UI

import '../core/app_theme.dart'; // ألوان العلامة
import 'glass_card.dart'; // بطاقة زجاجية

class DetectionStatusCard extends StatelessWidget { // بطاقة حالة (Face / Lipsing)
  const DetectionStatusCard({ // مُنشئ
    super.key, //
    required this.label, // عنوان صغير
    required this.value, // القيمة المعروضة
    required this.accent, // لون التمييز
    this.prominent = false, // خط أكبر؟
  }); //

  final String label; //
  final String value; //
  final Color accent; //
  final bool prominent; //

  @override // build
  Widget build(BuildContext context) { //
    return GlassCard( // بطاقة زجاجية
      borderRadius: 16, //
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), //
      child: Column( // عمود
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [ //
          Text( // العنوان
            label, //
            style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                  color: Colors.white70, //
                ), //
          ), //
          const SizedBox(height: 6), // مسافة
          Text( // القيمة
            value, //
            style: (prominent // حجم الخط
                    ? Theme.of(context).textTheme.headlineSmall //
                    : Theme.of(context).textTheme.titleMedium) //
                ?.copyWith( //
              color: accent, //
              fontWeight: FontWeight.w700, //
            ), //
          ), //
        ], //
      ), //
    ); //
  } // نهاية build
} // نهاية DetectionStatusCard

class LetterChip extends StatelessWidget { // زر صغير لحرف A-E
  const LetterChip({ // مُنشئ
    super.key, //
    required this.letter, // الحرف
    required this.active, // هل هو المكتشف؟
    required this.onTap, // عند الضغط
    this.target = false, // هل هو الهدف للتدريب؟
  }); //

  final String letter; //
  final bool active; //
  final bool target; //
  final VoidCallback onTap; //

  @override // build
  Widget build(BuildContext context) { //
    final borderColor = target // لون الحدود
        ? AppTheme.brandBlue //
        : active //
            ? AppTheme.brandTeal //
            : Colors.white24; //

    return GestureDetector( // يلتقط اللمس
      onTap: onTap, //
      child: AnimatedContainer( // حاوية متحركة
        duration: const Duration(milliseconds: 180), //
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), //
        decoration: BoxDecoration( // تنسيق
          color: active //
              ? AppTheme.brandTeal.withValues(alpha: 0.25) //
              : target //
                  ? AppTheme.brandBlue.withValues(alpha: 0.18) //
                  : Colors.white.withValues(alpha: 0.08), //
          borderRadius: BorderRadius.circular(12), //
          border: Border.all( //
            color: borderColor, //
            width: active || target ? 1.5 : 1, //
          ), //
        ), //
        child: Text( // الحرف
          letter, //
          style: Theme.of(context).textTheme.titleMedium?.copyWith( //
                color: active //
                    ? AppTheme.brandTeal //
                    : target //
                        ? AppTheme.brandBlue //
                        : Colors.white54, //
                fontWeight: active || target ? FontWeight.w700 : FontWeight.w500, //
              ), //
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية LetterChip

class MouthMetricTile extends StatelessWidget { // بلاطة مقياس فم واحد
  const MouthMetricTile({super.key, required this.label, required this.value}); //

  final String label; // اسم المقياس
  final int value; // القيمة %

  @override // build
  Widget build(BuildContext context) { //
    return Expanded( // يملأ المساحة في Row
      child: Container( //
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), //
        decoration: BoxDecoration( //
          color: Colors.white.withValues(alpha: 0.08), //
          borderRadius: BorderRadius.circular(12), //
          border: Border.all(color: Colors.white24), //
        ), //
        child: Column( //
          crossAxisAlignment: CrossAxisAlignment.start, //
          children: [ //
            Text(label, style: Theme.of(context).textTheme.bodySmall), //
            const SizedBox(height: 4), //
            Text('$value%', style: Theme.of(context).textTheme.titleSmall), //
          ], //
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية MouthMetricTile
