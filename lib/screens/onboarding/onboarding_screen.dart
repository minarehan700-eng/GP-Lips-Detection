import 'package:flutter/material.dart'; // Flutter UI

import '../../core/app_navigation.dart'; // انتقالات
import '../../widgets/gradient_background.dart'; // خلفية
import '../home_screen.dart'; // الشاشة الرئيسية
import 'onboarding_page.dart'; // صفحة onboarding
import 'onboarding_page_data.dart'; // بيانات الصفحات

/// تُعرض بعد splash في كل تشغيل — لا تُتخطى بالحفظ.
class OnboardingScreen extends StatefulWidget { // شاشة onboarding
  const OnboardingScreen({super.key}); //

  @override // createState
  State<OnboardingScreen> createState() => _OnboardingScreenState(); //
} // نهاية OnboardingScreen

class _OnboardingScreenState extends State<OnboardingScreen> { // حالة الشاشة
  final _pageController = PageController(); // متحكم PageView
  int _currentPage = 0; // رقم الصفحة الحالية

  static const _pages = OnboardingPageData.pages; // الصفحات
  bool get _isLastPage => _currentPage >= _pages.length - 1; // آخر صفحة؟

  @override // dispose
  void dispose() { //
    _pageController.dispose(); //
    super.dispose(); //
  } // نهاية dispose

  void _goHome() { // الانتقال للرئيسية
    Navigator.of(context).pushReplacement( //
      AppNavigation.fadeTransition(const HomeScreen()), //
    ); //
  } // نهاية _goHome

  void _onNext() { // زر Next / Get Started
    if (_isLastPage) { //
      _goHome(); //
      return; //
    } //
    _pageController.nextPage( // الصفحة التالية
      duration: const Duration(milliseconds: 320), //
      curve: Curves.easeOutCubic, //
    ); //
  } // نهاية _onNext

  @override // build
  Widget build(BuildContext context) { //
    return Scaffold( //
      body: GradientBackground( //
        child: SafeArea( //
          child: Column( //
            children: [ //
              Align( // زر Skip
                alignment: Alignment.centerRight, //
                child: TextButton( //
                  onPressed: _goHome, //
                  child: const Text('Skip'), //
                ), //
              ), //
              Expanded( // PageView
                child: PageView.builder( //
                  controller: _pageController, //
                  itemCount: _pages.length, //
                  onPageChanged: (index) => setState(() => _currentPage = index), //
                  itemBuilder: (_, index) => OnboardingPage(data: _pages[index]), //
                ), //
              ), //
              _PageDots(count: _pages.length, index: _currentPage), // نقاط
              const SizedBox(height: 20), //
              Padding( // زر Next
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), //
                child: SizedBox( //
                  width: double.infinity, //
                  child: FilledButton( //
                    onPressed: _onNext, //
                    child: Text(_isLastPage ? 'Get Started' : 'Next'), //
                  ), //
                ), //
              ), //
            ], //
          ), //
        ), //
      ), //
    ); //
  } // نهاية build
} // نهاية _OnboardingScreenState

class _PageDots extends StatelessWidget { // نقاط مؤشر الصفحة
  const _PageDots({required this.count, required this.index}); //

  final int count; // عدد الصفحات
  final int index; // الصفحة النشطة

  @override // build
  Widget build(BuildContext context) { //
    return Row( //
      mainAxisAlignment: MainAxisAlignment.center, //
      children: List.generate(count, (i) { // لكل صفحة
        final active = i == index; //
        return AnimatedContainer( //
          duration: const Duration(milliseconds: 220), //
          margin: const EdgeInsets.symmetric(horizontal: 4), //
          width: active ? 22 : 8, // النشطة أعرض
          height: 8, //
          decoration: BoxDecoration( //
            color: active ? Colors.white : Colors.white30, //
            borderRadius: BorderRadius.circular(8), //
          ), //
        ); //
      }), //
    ); //
  } // نهاية build
} // نهاية _PageDots
