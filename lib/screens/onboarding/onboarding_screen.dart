import 'package:flutter/material.dart';

import '../../core/app_navigation.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/gradient_background.dart';
import '../home_screen.dart';
import 'onboarding_page.dart';
import 'onboarding_page_data.dart';

/// Onboarding walkthrough shown after splash on every launch (not skippable via persistence).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Controls which page the swipeable [PageView] is showing.
  final _pageController = PageController();

  /// Index of the page on screen, used to fill the dots and the button label.
  int _currentPage = 0;

  bool get _isLastPage => _currentPage >= OnboardingPageData.pageCount - 1;

  @override
  void dispose() {
    // Controllers hold animation resources and must be released by hand.
    _pageController.dispose();
    super.dispose();
  }

  /// Goes to the home screen, replacing onboarding so the back button cannot
  /// return to it.
  void _goHome() {
    Navigator.of(context).pushReplacement(
      AppNavigation.fadeTransition(const HomeScreen()),
    );
  }

  /// Handles the bottom button: it advances one page, or finishes onboarding
  /// when the last page is already showing.
  void _onNext() {
    if (_isLastPage) {
      _goHome();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = OnboardingPageData.pages(l10n);
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                // centerEnd, not centerRight: in Arabic the whole layout
                // mirrors and Skip belongs on the left.
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _goHome,
                  child: Text(l10n.skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (_, index) => OnboardingPage(data: pages[index]),
                ),
              ),
              _PageDots(count: pages.length, index: _currentPage),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onNext,
                    child: Text(_isLastPage ? l10n.getStarted : l10n.next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The row of dots showing how many pages there are and which one is open.
/// The current dot stretches into a short bar so it is easy to spot.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  /// Total number of pages.
  final int count;

  /// Index of the page currently on screen.
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white30,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
