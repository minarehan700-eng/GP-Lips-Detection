import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why an unlock attempt did not succeed.
enum UnlockResult {
  /// The PIN matched.
  ok,

  /// Wrong PIN.
  wrong,

  /// Too many wrong tries; [AppLock.lockedUntil] says when to try again.
  lockedOut,
}

/// A PIN lock over the practice history.
///
/// What this defends against, precisely:
/// somebody who picks up an unlocked phone. Practice history says how well a
/// person can make speech shapes, which is health-adjacent information about a
/// disability, and this app is exactly the sort a family shares. That is a
/// real threat and this is a proportionate answer to it.
///
/// What it does not defend against, and does not pretend to: an attacker with
/// the device unlocked and a debugger attached. `shared_preferences` is not
/// encrypted storage, and a rooted phone can read it. Claiming otherwise would
/// be worse than claiming nothing.
///
/// There is deliberately no account, no server and no password reset. The app
/// has no network code at all, so there is nothing to authenticate against —
/// a login screen here would be decoration over an empty room.
class AppLock {
  AppLock({Random? random}) : _random = random ?? Random.secure();

  static const String saltKey = 'lock_salt';
  static const String hashKey = 'lock_hash';
  static const String iterationsKey = 'lock_iterations';
  static const String failuresKey = 'lock_failures';
  static const String lockedUntilKey = 'lock_until_ms';

  /// PBKDF2 rounds.
  ///
  /// A four-digit PIN has ten thousand possibilities, so the only thing
  /// standing between a stolen preferences file and the PIN is how long each
  /// guess takes. This makes a full sweep cost minutes rather than
  /// milliseconds. It is deliberately high enough to be felt (~100 ms on a
  /// mid-range phone) because the user pays it once per unlock and an attacker
  /// pays it ten thousand times.
  static const int iterations = 120000;

  static const int saltBytes = 16;
  static const int keyBytes = 32;

  static const int minPinLength = 4;
  static const int maxPinLength = 12;

  /// Wrong tries allowed before the lock-out starts.
  static const int freeAttempts = 3;

  /// Each failure past [freeAttempts] doubles the wait, up to [maxBackoff].
  static const Duration baseBackoff = Duration(seconds: 15);
  static const Duration maxBackoff = Duration(minutes: 30);

  final Random _random;

  /// Whether a PIN has been set.
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(hashKey) != null;
  }

  /// When the lock-out ends, or null when there is none.
  Future<DateTime?> get lockedUntil async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(lockedUntilKey);
    if (ms == null) {
      return null;
    }
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    return until.isAfter(DateTime.now()) ? until : null;
  }

  /// Sets or replaces the PIN.
  ///
  /// Throws [ArgumentError] for a PIN outside the allowed length, so a caller
  /// cannot store a one-digit lock by accident.
  Future<void> setPin(String pin) async {
    if (pin.length < minPinLength || pin.length > maxPinLength) {
      throw ArgumentError.value(
        pin.length,
        'pin.length',
        'must be between $minPinLength and $maxPinLength characters',
      );
    }
    final salt = _randomBytes(saltBytes);
    final hash = deriveKey(pin: pin, salt: salt, iterations: iterations);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(saltKey, base64Encode(salt));
    await prefs.setString(hashKey, base64Encode(hash));
    await prefs.setInt(iterationsKey, iterations);
    await _clearFailures(prefs);
  }

  /// Removes the lock. Requires the current PIN, so someone holding the phone
  /// cannot simply switch protection off.
  Future<bool> removePin(String currentPin) async {
    if (await verify(currentPin) != UnlockResult.ok) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(saltKey);
    await prefs.remove(hashKey);
    await prefs.remove(iterationsKey);
    await _clearFailures(prefs);
    return true;
  }

  /// Checks a PIN, applying the lock-out.
  Future<UnlockResult> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();

    final storedHash = prefs.getString(hashKey);
    final storedSalt = prefs.getString(saltKey);
    if (storedHash == null || storedSalt == null) {
      // No lock set, so nothing to refuse.
      return UnlockResult.ok;
    }

    if (await lockedUntil != null) {
      return UnlockResult.lockedOut;
    }

    final rounds = prefs.getInt(iterationsKey) ?? iterations;
    final candidate = deriveKey(
      pin: pin,
      salt: base64Decode(storedSalt),
      iterations: rounds,
    );

    if (constantTimeEquals(candidate, base64Decode(storedHash))) {
      await _clearFailures(prefs);
      return UnlockResult.ok;
    }

    await _recordFailure(prefs);
    return UnlockResult.wrong;
  }

  Future<void> _recordFailure(SharedPreferences prefs) async {
    final failures = (prefs.getInt(failuresKey) ?? 0) + 1;
    await prefs.setInt(failuresKey, failures);

    if (failures <= freeAttempts) {
      return;
    }
    // Doubling rather than a fixed delay: a fixed one is a fine annoyance for
    // the owner and no obstacle at all to a script.
    final steps = failures - freeAttempts - 1;
    var wait = baseBackoff * (1 << steps.clamp(0, 20));
    if (wait > maxBackoff) {
      wait = maxBackoff;
    }
    await prefs.setInt(
      lockedUntilKey,
      DateTime.now().add(wait).millisecondsSinceEpoch,
    );
  }

  Future<void> _clearFailures(SharedPreferences prefs) async {
    await prefs.remove(failuresKey);
    await prefs.remove(lockedUntilKey);
  }

  Uint8List _randomBytes(int count) {
    return Uint8List.fromList(
      List<int>.generate(count, (_) => _random.nextInt(256)),
    );
  }

  /// PBKDF2-HMAC-SHA256, as specified in RFC 8018.
  ///
  /// Written out rather than pulled from a package because the whole of it is
  /// twenty lines, and it is checked against the published test vectors in
  /// `test/app_lock_test.dart` — an implementation nobody has verified against
  /// a known answer is not worth trusting with a PIN.
  static Uint8List deriveKey({
    required String pin,
    required Uint8List salt,
    required int iterations,
    int length = keyBytes,
  }) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    final output = BytesBuilder();
    var block = 1;

    while (output.length < length) {
      // U1 = HMAC(password, salt || INT_32_BE(block))
      final firstInput = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt);
      final view = ByteData.view(firstInput.buffer);
      view.setUint32(salt.length, block, Endian.big);

      var u = Uint8List.fromList(hmac.convert(firstInput).bytes);
      final accumulated = Uint8List.fromList(u);

      for (var round = 1; round < iterations; round++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var i = 0; i < accumulated.length; i++) {
          accumulated[i] ^= u[i];
        }
      }

      output.add(accumulated);
      block++;
    }

    return Uint8List.fromList(output.toBytes().sublist(0, length));
  }

  /// Compares two byte strings without leaking where they first differ.
  ///
  /// A plain `==` returns as soon as it finds a mismatch, so how long it took
  /// tells an attacker how much of their guess was right. Here every byte is
  /// always looked at.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
