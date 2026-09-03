import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';

/// One place to reach every screen.
///
/// Why a drawer rather than more icons in the bar:
/// there are seven destinations now. Seven icons in an app bar is a row of
/// unlabelled glyphs nobody can tell apart, and it is worse still for a screen
/// reader, where each is announced only by whatever tooltip it happens to
/// carry. A drawer gives every destination a name and an icon, in a list that
/// reads top to bottom in any language.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.current,
    required this.onSelected,
  });

  /// Which destination is showing, so it can be marked rather than offered.
  final AppDestination current;

  /// Called with the chosen destination after the drawer closes.
  final void Function(AppDestination destination) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Drawer(
      backgroundColor: const Color(0xFF0E1420),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.splashTagline,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            for (final destination in AppDestination.values)
              _DrawerRow(
                destination: destination,
                selected: destination == current,
                label: labelFor(l10n, destination),
                onTap: () {
                  Navigator.of(context).pop();
                  if (destination != current) {
                    onSelected(destination);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// The translated name for a destination.
  static String labelFor(AppLocalizations l10n, AppDestination destination) {
    return switch (destination) {
      AppDestination.detect => l10n.homeTitle,
      AppDestination.practice => l10n.practice,
      AppDestination.calibrate => l10n.calibrate,
      AppDestination.words => l10n.words,
      AppDestination.shapeGuide => l10n.chart,
      AppDestination.progress => l10n.progress,
      AppDestination.settings => l10n.settings,
      AppDestination.about => l10n.about,
    };
  }
}

/// Everywhere the app can go.
///
/// An enum rather than loose route strings, so adding a screen without giving
/// it a drawer entry and a translated name does not compile.
enum AppDestination {
  detect(Icons.videocam_rounded),
  practice(Icons.school_rounded),
  calibrate(Icons.tune_rounded),
  words(Icons.chat_bubble_outline_rounded),
  shapeGuide(Icons.menu_book_rounded),
  progress(Icons.insights_rounded),
  settings(Icons.settings_rounded),
  about(Icons.info_outline_rounded);

  const AppDestination(this.icon);

  final IconData icon;
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.destination,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        destination.icon,
        color: selected ? AppTheme.brandTeal : Colors.white60,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.brandTeal : Colors.white,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      selected: selected,
      // Marked as selected for a screen reader too, not only by colour.
      onTap: onTap,
    );
  }
}
