import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'onboarding_page_data.dart';

/// Draws one onboarding page from its [OnboardingPageData].
///
/// All three pages share this single layout, so only the words and the icon
/// change between them.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.data});

  /// The words and icon for this page.
  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scrollable, and centred only while there is room to spare.
    //
    // At the largest accessibility text sizes this page needs far more height
    // than the screen has — a fixed Column overflowed by well over a thousand
    // pixels, which the user sees as clipped text behind warning stripes.
    // Letting it scroll costs nothing at normal sizes, where the content still
    // sits in the middle of the page.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // clamped at zero: on a short window, or with a tall system inset,
          // the subtraction goes negative and BoxConstraints rejects it.
          minHeight: (MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  32)
              .clamp(0.0, double.infinity),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF5E7BFF), Color(0xFF9D56FF)],
              ),
            ),
            child: Icon(data.icon, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          if (data.bullets.isNotEmpty) ...[
            const SizedBox(height: 24),
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final bullet in data.bullets)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: AppTheme.brandTeal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bullet,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }
}
