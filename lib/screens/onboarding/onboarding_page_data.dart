import 'package:flutter/material.dart';

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

  /// The three pages shown after the splash screen, in order:
  /// what lipsing is, what the letters mean, and how to hold the camera.
  static const pages = [
    OnboardingPageData(
      icon: Icons.record_voice_over_rounded,
      title: 'What is lipsing?',
      body:
          'Lipsing is mouthing words without voice — common in sign language. '
          'This app watches your mouth shape in real time and tells you when lipsing is detected.',
      bullets: [
        'Face must be visible in the camera',
        'Green box highlights your mouth region',
        '“Lipsing: Yes” means active mouth movement',
      ],
    ),
    OnboardingPageData(
      icon: Icons.abc_rounded,
      title: 'Letters A – E',
      body:
          'MediaPipe tracks mouth landmarks and maps shapes to viseme letters A through E.',
      bullets: [
        'A — wide open mouth',
        'B — lips closed',
        'C — rounded / puckered lips',
        'D — slightly open',
        'E — smile shape',
      ],
    ),
    OnboardingPageData(
      icon: Icons.videocam_rounded,
      title: 'Using the camera',
      body:
          'Hold the phone at eye level, face the front camera, and keep good lighting.',
      bullets: [
        'Tap a letter chip to set a practice target',
        'Adjust thresholds in Settings if detection feels off',
        'Works fully offline — no internet required',
      ],
    ),
  ];
}
