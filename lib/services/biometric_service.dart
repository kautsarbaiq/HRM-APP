/// BiometricService — web-compatible abstraction layer for biometric authentication.
/// On web: simulates a successful scan after a delay.
/// On mobile: ready to wire into `local_auth` plugin.
class BiometricService {
  /// Check if biometric auth is available on this device.
  /// Always returns true on web (simulated).
  static Future<bool> isAvailable() async {
    // For mobile integration, replace with:
    // final auth = LocalAuthentication();
    // return await auth.canCheckBiometrics;
    return true;
  }

  /// Authenticate the user via biometrics.
  /// Returns true on success, false on failure.
  static Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    // Simulate a 2-second biometric scan
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // For mobile integration, replace with:
    // final auth = LocalAuthentication();
    // return await auth.authenticate(localizedReason: reason);
    return true;
  }
}
