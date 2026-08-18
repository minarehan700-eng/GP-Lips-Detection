import 'package:flutter/material.dart'; // استيراد مكتبة Flutter لبناء الواجهات

import 'core/app_theme.dart'; // استيراد ملف ألوان وتنسيق التطبيق
import 'screens/splash_screen.dart'; // استيراد شاشة البداية (Splash)

void main() { // نقطة بداية تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized(); // تهيئة Flutter قبل أي عمليات أخرى
  runApp(const LipsOfflineApp()); // تشغيل التطبيق الرئيسي
} // نهاية الدالة main

class LipsOfflineApp extends StatelessWidget { // كلاس التطبيق الرئيسي (بدون حالة داخلية)
  const LipsOfflineApp({super.key}); // مُنشئ مع مفتاح اختياري للـ Widget

  @override // تجاوز الدالة المطلوبة من StatelessWidget
  Widget build(BuildContext context) { // بناء شجرة الواجهات
    return MaterialApp( // تطبيق Material Design
      debugShowCheckedModeBanner: false, // إخفاء شريط "DEBUG" في الزاوية
      title: 'Lips Offline', // عنوان التطبيق (للمهام الداخلية)
      theme: AppTheme.dark(), // استخدام الثيم الداكن من AppTheme
      home: const SplashScreen(), // الشاشة الأولى عند فتح التطبيق
    ); // نهاية MaterialApp
  } // نهاية build
} // نهاية كلاس LipsOfflineApp
