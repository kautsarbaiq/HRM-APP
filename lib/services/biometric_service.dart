import 'package:local_auth/local_auth.dart';

/// BiometricService — real biometric authentication using local_auth plugin.
/// Supports fingerprint, face recognition, and iris on supported devices.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric auth is available on this device.
  /// Returns true if the device supports biometrics and has enrolled credentials.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (face, fingerprint, iris).
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return <BiometricType>[];
    }
  }

  /// Authenticate the user via the device's native biometric dialog.
  /// Returns true on success, false on failure or cancellation.
  static Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
