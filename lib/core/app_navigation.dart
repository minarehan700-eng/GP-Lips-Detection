import 'package:flutter/material.dart'; // استيراد Flutter للتنقل بين الشاشات

class AppNavigation { // كلاس مساعد لانتقالات الشاشات
  static Route<T> fadeTransition<T>(Widget page) { // إنشاء مسار بانتقال fade + slide
    return PageRouteBuilder<T>( // بناء مسار مخصص
      pageBuilder: (_, _, _) => page, // الشاشة التي سننتقل إليها
      transitionDuration: const Duration(milliseconds: 420), // مدة الانتقال للأمام
      reverseTransitionDuration: const Duration(milliseconds: 280), // مدة الرجوع للخلف
      transitionsBuilder: (_, animation, secondaryAnimation, child) { // بناء تأثير الحركة
        final offset = Tween<Offset>( // حركة انزلاق بسيطة من الأسفل
          begin: const Offset(0, 0.04), // نقطة البداية (قليلاً للأسفل)
          end: Offset.zero, // نقطة النهاية (المكان الطبيعي)
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)); // منحنى حركة ناعم

        return FadeTransition( // تأثير ظهور تدريجي (شفافية)
          opacity: animation, // ربط الشفافية بالـ animation
          child: SlideTransition(position: offset, child: child), // إضافة انزلاق مع الـ fade
        ); // نهاية FadeTransition
      }, // نهاية transitionsBuilder
    ); // نهاية PageRouteBuilder
  } // نهاية fadeTransition
} // نهاية AppNavigation
