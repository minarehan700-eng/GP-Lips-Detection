import 'package:flutter/material.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> bullets;

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
