import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// What the app does, what it does not do, and where the data goes.
///
/// The "cannot" half is not modesty. Somebody relying on this to understand
/// another person needs to know its limits, and an app that overstates itself
/// is worse than one that is clear about being a practice tool.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l10n.about)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              Text(l10n.aboutWhat,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              _Point(
                icon: Icons.check_circle_outline_rounded,
                colour: AppTheme.successGreen,
                text: l10n.aboutCan,
              ),
              const SizedBox(height: 10),
              _Point(
                icon: Icons.info_outline_rounded,
                colour: Colors.orangeAccent,
                text: l10n.aboutCannot,
              ),
              const SizedBox(height: 24),
              Text(l10n.aboutPrivacy,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              _Point(
                icon: Icons.lock_outline_rounded,
                colour: AppTheme.brandTeal,
                text: l10n.aboutPrivacyBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.colour,
    required this.text,
  });

  final IconData icon;
  final Color colour;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
