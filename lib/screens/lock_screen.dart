import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_lock.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Asks for the PIN before the app can be used.
///
/// Shown only when a PIN has been set. There is no "forgot my PIN" link and no
/// recovery: with no account and no server there is nothing to recover
/// against, and a bypass that worked for a forgetful owner would work just as
/// well for anybody else holding the phone.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked, this.lock});

  final VoidCallback onUnlocked;

  /// Injectable so a test can supply a lock backed by mock storage. Null means
  /// the real one; it is not created in the constructor because AppLock needs
  /// a secure random and so cannot be const.
  final AppLock? lock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final AppLock _lock = widget.lock ?? AppLock();
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _checking = true;
      _error = null;
    });

    final result = await _lock.verify(_controller.text);
    if (!mounted) return;

    switch (result) {
      case UnlockResult.ok:
        widget.onUnlocked();
      case UnlockResult.wrong:
        unawaitedShake();
        setState(() {
          _error = l10n.securityWrong;
          _checking = false;
        });
        _controller.clear();
      case UnlockResult.lockedOut:
        setState(() {
          _error = l10n.securityLockedOut;
          _checking = false;
        });
        _controller.clear();
    }
  }

  /// A wrong PIN buzzes as well as reads — the person may not be able to hear
  /// an error sound, and may not be looking at the field.
  void unawaitedShake() {
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 34, color: AppTheme.brandTeal),
                      const SizedBox(height: 14),
                      Text(
                        l10n.securityEnterPin,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: AppLock.maxPinLength,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          counterText: '',
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _checking ? null : _submit,
                        child: Text(l10n.securityUnlock),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
