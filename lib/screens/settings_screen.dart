import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_preferences.dart';
import '../core/detector_settings.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Lets the user tune how sensitive the detection is.
///
/// Why this screen exists:
/// Faces, cameras and lighting differ, so the built-in thresholds do not suit
/// everyone. Three sliders let the user make detection stricter or more
/// forgiving, and the choice is saved on the phone.
///
/// Changes are held in memory while sliding and only written when the user
/// presses Save, so an accidental drag does not overwrite a good setting.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// The values shown by the sliders right now (not yet saved).
  DetectorSettings _settings = DetectorSettings.defaults;

  /// True while the saved values are being read from the phone.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the saved settings and shows them on the sliders.
  ///
  /// The `mounted` check guards against the user leaving the screen before
  /// the read finishes; calling setState after that would throw.
  Future<void> _load() async {
    final loaded = await DetectorSettings.load();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loading = false;
    });
  }

  /// Writes the current slider values to the phone and confirms to the user.
  ///
  /// The home screen reloads the detectors when this screen is closed, so the
  /// new values take effect as soon as the user goes back.
  Future<void> _save() async {
    await _settings.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
    );
  }

  /// Puts the sliders back to the built-in defaults.
  /// Nothing is stored until the user presses Save.
  void _resetToDefaults() {
    setState(() {
      _settings = DetectorSettings.defaults;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preferences = AppPreferencesScope.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.detectorThresholds,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      GlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SliderRow(
                              label: l10n.mouthOpenThreshold,
                              value: _settings.mouthOpenThreshold,
                              display: _settings.mouthOpenThreshold.toStringAsFixed(2),
                              min: DetectorSettings.mouthOpenMin,
                              max: DetectorSettings.mouthOpenMax,
                              divisions: DetectorSettings.mouthOpenDivisions,
                              hint: l10n.mouthOpenThresholdHelp,
                              onChanged: (v) => setState(
                                () => _settings = _settings.copyWith(mouthOpenThreshold: v),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SliderRow(
                              label: l10n.motionThreshold,
                              value: _settings.motionThreshold,
                              display: _settings.motionThreshold.toStringAsFixed(3),
                              min: DetectorSettings.motionMin,
                              max: DetectorSettings.motionMax,
                              divisions: DetectorSettings.motionDivisions,
                              hint: l10n.motionThresholdHelp,
                              onChanged: (v) => setState(
                                () => _settings = _settings.copyWith(motionThreshold: v),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SliderRow(
                              label: l10n.letterMinScore,
                              value: _settings.letterMinScore,
                              display: _settings.letterMinScore.toStringAsFixed(2),
                              min: DetectorSettings.letterMinScoreMin,
                              max: DetectorSettings.letterMinScoreMax,
                              divisions: DetectorSettings.letterMinScoreDivisions,
                              hint: l10n.letterMinScoreHelp,
                              onChanged: (v) => setState(
                                () => _settings = _settings.copyWith(letterMinScore: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.language,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      GlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LanguagePicker(preferences: preferences),
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: preferences.value.hapticsEnabled,
                              onChanged: preferences.setHaptics,
                              title: Text(l10n.haptics),
                              subtitle: Text(l10n.hapticsHelp),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: preferences.value.announceDetections,
                              onChanged: preferences.setAnnounceDetections,
                              title: Text(l10n.announceDetections),
                              subtitle: Text(l10n.announceDetectionsHelp),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(l10n.saveSettings),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _resetToDefaults,
                          child: Text(l10n.resetDefaults),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// One labelled slider: title, current value, the slider, and a short hint.
///
/// All three settings look and behave the same, so they share this widget
/// instead of repeating the same layout three times.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.display,
    required this.min,
    required this.max,
    required this.divisions,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String display;
  final double min;
  final double max;
  final int divisions;
  final String hint;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(
              display,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.brandTeal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Slider(
          // Clamped because a value saved by an older version of the app
          // could sit outside today's range, and Slider throws if it does.
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Text(
          hint,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white60,
              ),
        ),
      ],
    );
  }
}

/// Lets the user pick a language, or follow whatever the device is set to.
///
/// The list comes from the generated localizations, so a new .arb file appears
/// here without this widget being touched. Each language is written in its own
/// script — someone looking for Arabic is looking for "العربية", not "Arabic".
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.preferences});

  final AppPreferencesController preferences;

  /// What each shipped language calls itself.
  static const _endonyms = <String, String>{
    'en': 'English',
    'ar': 'العربية',
    'es': 'Español',
    'fr': 'Français',
  };

  static String nameFor(String code) => _endonyms[code] ?? code.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final codes = AppPreferences.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet()
        .toList()
      ..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.languageSystem),
          selected: preferences.value.localeCode == null,
          onSelected: (_) => preferences.setLocale(null),
        ),
        for (final code in codes)
          ChoiceChip(
            label: Text(nameFor(code)),
            selected: preferences.value.localeCode == code,
            onSelected: (_) => preferences.setLocale(code),
          ),
      ],
    );
  }
}
