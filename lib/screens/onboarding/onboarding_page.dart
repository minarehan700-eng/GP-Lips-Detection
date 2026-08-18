import 'package:flutter/material.dart'; // Flutter UI

import '../../core/app_theme.dart'; // ألوان
import '../../widgets/glass_card.dart'; // بطاقة
import 'onboarding_page_data.dart'; // بيانات الصفحة

class OnboardingPage extends StatelessWidget { // واجهة صفحة onboarding واحدة
  const OnboardingPage({super.key, required this.data}); //

  final OnboardingPageData data; // بيانات هذه الصفحة

  @override // build
  Widget build(BuildContext context) { //
    final theme = Theme.of(context); // ثيم للنصوص

    return Padding( // حشو أفقي
      padding: const EdgeInsets.symmetric(horizontal: 24), //
      child: Column( //
        mainAxisAlignment: MainAxisAlignment.center, //
        children: [ //
          Container( // أيقونة داخل مربع متدرج
            width: 88, //
            height: 88, //
            decoration: BoxDecoration( //
              borderRadius: BorderRadius.circular(28), //
              gradient: const LinearGradient( //
                colors: [Color(0xFF5E7BFF), Color(0xFF9D56FF)], //
              ), //
            ), //
            child: Icon(data.icon, size: 44, color: Colors.white), //
          ), //
          const SizedBox(height: 28), //
          Text( // العنوان
            data.title, //
            textAlign: TextAlign.center, //
            style: theme.textTheme.headlineSmall?.copyWith( //
              fontWeight: FontWeight.w700, //
            ), //
          ), //
          const SizedBox(height: 14), //
          Text( // النص
            data.body, //
            textAlign: TextAlign.center, //
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70), //
          ), //
          if (data.bullets.isNotEmpty) ...[ // قائمة نقاط
            const SizedBox(height: 24), //
            GlassCard( //
              borderRadius: 16, //
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), //
              child: Column( //
                crossAxisAlignment: CrossAxisAlignment.start, //
                children: [ //
                  for (final bullet in data.bullets) // لكل نقطة
                    Padding( //
                      padding: const EdgeInsets.symmetric(vertical: 5), //
                      child: Row( //
                        crossAxisAlignment: CrossAxisAlignment.start, //
                        children: [ //
                          const Icon( //
                            Icons.check_circle_outline_rounded, //
                            size: 18, //
                            color: AppTheme.brandTeal, //
                          ), //
                          const SizedBox(width: 10), //
                          Expanded( //
                            child: Text( //
                              bullet, //
                              style: theme.textTheme.bodyMedium?.copyWith( //
                                color: Colors.white70, //
                              ), //
                            ), //
                          ), //
                        ], //
                      ), //
                    ), //
                ], //
              ), //
            ), //
          ], //
        ], //
      ), //
    ); //
  } // نهاية build
} // نهاية OnboardingPage
