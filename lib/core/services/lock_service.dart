import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockService {
  LockService(this._localAuth);

  final LocalAuthentication _localAuth;

  static const _pinHashPrefix = 'lock.pinHash';
  static const _biometricPrefix = 'lock.biometric';

  Future<bool> authenticateWithBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      return false;
    }

    return _localAuth.authenticate(
      localizedReason: 'Unlock your private health tracker',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }

  Future<LockPreferences> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = prefs.getString(_key(_pinHashPrefix, userId));
    return LockPreferences(
      pinEnabled: pinHash != null,
      biometricEnabled: prefs.getBool(_key(_biometricPrefix, userId)) ?? false,
    );
  }

  Future<void> setPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_pinHashPrefix, userId), _encodePin(pin));
  }

  Future<void> clearPin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_pinHashPrefix, userId));
    await prefs.remove(_key(_biometricPrefix, userId));
  }

  Future<bool> verifyPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key(_pinHashPrefix, userId));
    if (stored == null) {
      return false;
    }
    final parts = stored.split(':');
    if (parts.length != 2) {
      return false;
    }
    final candidate = _hashPin(parts.first, pin);
    return _constantTimeEquals(parts.last, candidate);
  }

  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_biometricPrefix, userId), enabled);
  }

  String _key(String prefix, String userId) => '$prefix.$userId';

  String _encodePin(String pin) {
    final salt = _randomSalt();
    return '$salt:${_hashPin(salt, pin)}';
  }

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String salt, String pin) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return diff == 0;
  }
}

class LockPreferences {
  const LockPreferences({
    required this.pinEnabled,
    required this.biometricEnabled,
  });

  final bool pinEnabled;
  final bool biometricEnabled;

  static const empty = LockPreferences(
    pinEnabled: false,
    biometricEnabled: false,
  );

  LockPreferences copyWith({bool? pinEnabled, bool? biometricEnabled}) {
    return LockPreferences(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
