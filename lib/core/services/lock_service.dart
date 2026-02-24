import 'package:local_auth/local_auth.dart';

class LockService {
  LockService(this._localAuth);

  final LocalAuthentication _localAuth;

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
}
