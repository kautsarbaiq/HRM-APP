import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// BiometricService — App-side face enrollment and verification.
/// Stores a "Face Signature" (mocked hash) in SharedPreferences.
/// Does NOT rely on device OS biometrics (local_auth).
class BiometricService {
  static const _faceKey = 'enrolled_face_signature';
  static const _faceTimestampKey = 'enrolled_face_timestamp';
  static const _faceNameKey = 'enrolled_face_name';

  /// Check if a face has been enrolled in the app.
  static Future<bool> isFaceEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_faceKey) && prefs.getString(_faceKey)!.isNotEmpty;
  }

  /// Get the enrollment timestamp (for display purposes).
  static Future<String?> getEnrollmentTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_faceTimestampKey);
  }

  /// Get the enrolled user name.
  static Future<String?> getEnrolledName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_faceNameKey);
  }

  /// Enroll a new face. Generates a mock "face signature" hash
  /// and stores it in local storage.
  /// In a real app, this would capture facial features from the camera
  /// and convert them to a vector/embedding.
  static Future<String> enrollFace({String userName = 'Ahmad Razif'}) async {
    final prefs = await SharedPreferences.getInstance();

    // Generate a mock face signature (simulating a facial feature hash)
    final random = Random();
    final facePoints = List.generate(128, (_) => random.nextDouble());
    final signature = base64Encode(utf8.encode(facePoints.join(',')));

    // Store the signature
    await prefs.setString(_faceKey, signature);
    await prefs.setString(_faceTimestampKey, DateTime.now().toIso8601String());
    await prefs.setString(_faceNameKey, userName);

    return signature;
  }

  /// Verify a "live scan" against the stored face signature.
  /// In a real app, this would compare facial embeddings using
  /// cosine similarity or Euclidean distance.
  /// For this mock: simulates a 95% match rate.
  static Future<FaceVerifyResult> verifyFace() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_faceKey);

    if (stored == null || stored.isEmpty) {
      return FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'No face enrolled. Please register first.',
        needsEnrollment: true,
      );
    }

    // Simulate scanning delay (camera capture + processing)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock verification: 95% success rate to simulate real-world accuracy
    final random = Random();
    final confidence = 0.85 + random.nextDouble() * 0.14; // 85-99%
    final threshold = 0.80;
    final isMatch = confidence >= threshold;

    return FaceVerifyResult(
      success: isMatch,
      confidence: confidence,
      message: isMatch
          ? 'Identity verified (${(confidence * 100).toStringAsFixed(1)}% match)'
          : 'Face mismatch. Please try again.',
      needsEnrollment: false,
    );
  }

  /// Delete the enrolled face data.
  static Future<void> deleteFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_faceKey);
    await prefs.remove(_faceTimestampKey);
    await prefs.remove(_faceNameKey);
  }

  // ─── Legacy compatibility ───
  // These methods keep the old API surface working so nothing breaks.

  /// Always returns true since we handle face auth in-app.
  static Future<bool> isAvailable() async => true;

  /// Authenticate using the in-app face verification.
  static Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    final result = await verifyFace();
    return result.success;
  }
}

class FaceVerifyResult {
  final bool success;
  final double confidence;
  final String message;
  final bool needsEnrollment;

  const FaceVerifyResult({
    required this.success,
    required this.confidence,
    required this.message,
    this.needsEnrollment = false,
  });
}
