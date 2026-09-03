import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/app_lock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the PIN lock over practice history.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  String hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  group('PBKDF2-HMAC-SHA256', () {
    // Published vectors. An implementation nobody has checked against a known
    // answer is not worth trusting with a PIN, and hand-rolled PBKDF2 is very
    // easy to get subtly wrong — a mis-ordered counter or a missing XOR still
    // produces plausible-looking bytes.
    test('matches the published vector for c = 1', () {
      final key = AppLock.deriveKey(
        pin: 'password',
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 1,
      );

      expect(
        hex(key),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('matches the published vector for c = 2', () {
      final key = AppLock.deriveKey(
        pin: 'password',
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 2,
      );

      expect(
        hex(key),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('matches the published vector for c = 4096', () {
      final key = AppLock.deriveKey(
        pin: 'password',
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 4096,
      );

      expect(
        hex(key),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('a longer key spans more than one block', () {
      // SHA-256 gives 32 bytes per block, so 40 exercises the block-counter
      // path that a single-block test never reaches.
      final key = AppLock.deriveKey(
        pin: 'passwordPASSWORDpassword',
        salt: Uint8List.fromList(
            utf8.encode('saltSALTsaltSALTsaltSALTsaltSALTsalt')),
        iterations: 4096,
        length: 40,
      );

      expect(
        hex(key),
        '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1'
        'c635518c7dac47e9',
      );
    });

    test('a different salt gives a different key', () {
      final a = AppLock.deriveKey(
          pin: '1234', salt: Uint8List.fromList([1, 2, 3]), iterations: 10);
      final b = AppLock.deriveKey(
          pin: '1234', salt: Uint8List.fromList([3, 2, 1]), iterations: 10);

      // Two people choosing 1234 must not end up with the same stored hash,
      // or one cracked PIN cracks every phone at once.
      expect(hex(a), isNot(hex(b)));
    });
  });

  group('comparing safely', () {
    test('equal byte strings match', () {
      expect(AppLock.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('a difference anywhere is caught', () {
      expect(AppLock.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(AppLock.constantTimeEquals([9, 2, 3], [1, 2, 3]), isFalse);
    });

    test('different lengths never match', () {
      expect(AppLock.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('setting a PIN', () {
    test('the PIN itself is never stored', () async {
      await AppLock().setPin('4821');

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getKeys().map((k) => '${prefs.get(k)}').join('|');

      expect(stored.contains('4821'), isFalse,
          reason: 'the PIN appears in storage in the clear');
      expect(prefs.getString(AppLock.hashKey), isNotNull);
      expect(prefs.getString(AppLock.saltKey), isNotNull);
    });

    test('the salt is different every time', () async {
      await AppLock().setPin('4821');
      final prefs = await SharedPreferences.getInstance();
      final first = prefs.getString(AppLock.saltKey);

      await AppLock().setPin('4821');
      final second =
          (await SharedPreferences.getInstance()).getString(AppLock.saltKey);

      expect(first, isNot(second));
    });

    test('a too-short PIN is refused', () async {
      expect(() => AppLock().setPin('12'), throwsArgumentError);
    });

    test('no lock means nothing to unlock', () async {
      expect(await AppLock().isEnabled, isFalse);
      expect(await AppLock().verify('anything'), UnlockResult.ok);
    });
  });

  group('unlocking', () {
    test('the right PIN opens it', () async {
      final lock = AppLock();
      await lock.setPin('4821');

      expect(await lock.verify('4821'), UnlockResult.ok);
      expect(await lock.isEnabled, isTrue);
    });

    test('the wrong PIN does not', () async {
      final lock = AppLock();
      await lock.setPin('4821');

      expect(await lock.verify('0000'), UnlockResult.wrong);
    });

    test('repeated wrong guesses trigger a lock-out', () async {
      final lock = AppLock();
      await lock.setPin('4821');

      for (var i = 0; i < AppLock.freeAttempts + 1; i++) {
        expect(await lock.verify('0000'), UnlockResult.wrong);
      }

      // A four-digit PIN is ten thousand guesses. Unthrottled, that is a
      // couple of minutes of scripting.
      expect(await lock.verify('0000'), UnlockResult.lockedOut);
      expect(await lock.lockedUntil, isNotNull);
    });

    test('the lock-out blocks the correct PIN too', () async {
      // Otherwise an attacker simply keeps guessing through it.
      final lock = AppLock();
      await lock.setPin('4821');

      for (var i = 0; i < AppLock.freeAttempts + 2; i++) {
        await lock.verify('0000');
      }

      expect(await lock.verify('4821'), UnlockResult.lockedOut);
    });

    test('the wait grows with each further failure', () async {
      final lock = AppLock();
      await lock.setPin('4821');
      final prefs = await SharedPreferences.getInstance();

      for (var i = 0; i < AppLock.freeAttempts + 1; i++) {
        await lock.verify('0000');
      }
      final firstWait = prefs.getInt(AppLock.lockedUntilKey)!;

      // Clear the lock-out to allow one more attempt, as waiting it out would.
      await prefs.remove(AppLock.lockedUntilKey);
      await lock.verify('0000');
      final secondWait = prefs.getInt(AppLock.lockedUntilKey)!;

      expect(secondWait, greaterThan(firstWait));
    });

    test('a success clears the failure count', () async {
      final lock = AppLock();
      await lock.setPin('4821');

      await lock.verify('0000');
      await lock.verify('0000');
      expect(await lock.verify('4821'), UnlockResult.ok);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppLock.failuresKey), isNull);
    });
  });

  group('removing the lock', () {
    test('needs the current PIN', () async {
      final lock = AppLock();
      await lock.setPin('4821');

      // Somebody holding the phone must not be able to switch protection off.
      expect(await lock.removePin('0000'), isFalse);
      expect(await lock.isEnabled, isTrue);
    });

    test('works with the right PIN', () async {
      final lock = AppLock();
      await lock.setPin('4821');

      expect(await lock.removePin('4821'), isTrue);
      expect(await lock.isEnabled, isFalse);
    });
  });

  group('the salt source', () {
    test('uses the random it is given, so it can be tested', () async {
      // Random.secure() by default; injectable only so a test can be
      // deterministic. Nothing in the app passes a seeded Random.
      final lock = AppLock(random: Random(1));
      await lock.setPin('4821');

      final prefs = await SharedPreferences.getInstance();
      expect(base64Decode(prefs.getString(AppLock.saltKey)!),
          hasLength(AppLock.saltBytes));
    });
  });
}
