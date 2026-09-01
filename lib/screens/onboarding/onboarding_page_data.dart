import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The text and icon for one onboarding page.
///
/// The wording is kept here, apart from the widget that draws it, so the three
/// pages can be edited or reordered without touching any layout code.
class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  /// Icon shown in the coloured square at the top of the page.
  final IconData icon;

  /// The page heading.
  final String title;

  /// The main paragraph under the heading.
  final String body;

  /// Optional tick-list points, shown inside a glass card.
  final List<String> bullets;

  /// How many pages [pages] returns.
  ///
  /// Needed by the onboarding screen before it has a locale to build the list
  /// with. A test asserts the two agree, so this cannot drift.
  static const int pageCount = 3;

  /// The three pages shown after the splash screen, in order:
  /// what lipsing is, what the letters mean, and how to hold the camera.
  ///
  /// This is a function rather than a constant list because every string is
  /// translated, and a translation cannot be known until there is a locale to
  /// look it up in.
  static List<OnboardingPageData> pages(AppLocalizations l10n) => [
        OnboardingPageData(
          icon: Icons.record_voice_over_rounded,
          title: l10n.onboardLipsingTitle,
          body: l10n.onboardLipsingBody,
          bullets: [
            l10n.onboardLipsingPoint1,
            l10n.onboardLipsingPoint2,
            l10n.onboardLipsingPoint3,
          ],
        ),
        OnboardingPageData(
          icon: Icons.abc_rounded,
          title: l10n.onboardLettersTitle,
          body: l10n.onboardLettersBody,
          bullets: [
            l10n.onboardLetterA,
            l10n.onboardLetterB,
            l10n.onboardLetterC,
            l10n.onboardLetterD,
            l10n.onboardLetterE,
          ],
        ),
        OnboardingPageData(
          icon: Icons.videocam_rounded,
          title: l10n.onboardCameraTitle,
          body: l10n.onboardCameraBody,
          bullets: [
            l10n.onboardCameraPoint1,
            l10n.onboardCameraPoint2,
            l10n.onboardCameraPoint3,
          ],
        ),
      ];
}
