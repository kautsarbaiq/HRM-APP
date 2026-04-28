import 'dart:convert';
import 'dart:io';
import 'dart:math' show sqrt;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BiometricService — In-app face enrollment and verification using Google ML Kit.
/// Extracts facial landmarks (eye, nose, mouth positions) and stores them
/// as a "Face Signature" in SharedPreferences.
/// Does NOT rely on device OS biometrics (local_auth).
class BiometricService {
  static const _faceKey = 'enrolled_face_signature';
  static const _faceTimestampKey = 'enrolled_face_timestamp';
  static const _faceNameKey = 'enrolled_face_name';
  static const _faceLandmarksKey = 'enrolled_face_landmarks';

  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  /// Check if a face has been enrolled in the app.
  static Future<bool> isFaceEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_faceLandmarksKey) &&
        prefs.getString(_faceLandmarksKey)!.isNotEmpty;
  }

  /// Get the enrollment timestamp.
  static Future<String?> getEnrollmentTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_faceTimestampKey);
  }

  /// Get the enrolled user name.
  static Future<String?> getEnrolledName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_faceNameKey);
  }

  /// Detect faces from an image file. Returns list of detected Face objects.
  static Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  /// Extract normalized landmark coordinates from a Face object.
  /// Returns a Map of landmark type -> {x, y} normalized to face bounding box.
  static Map<String, Map<String, double>> _extractLandmarks(Face face) {
    final landmarks = <String, Map<String, double>>{};
    final box = face.boundingBox;
    final w = box.width;
    final h = box.height;

    for (final type in FaceLandmarkType.values) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        // Normalize positions relative to the bounding box
        landmarks[type.name] = {
          'x': (landmark.position.x - box.left) / w,
          'y': (landmark.position.y - box.top) / h,
        };
      }
    }

    return landmarks;
  }

  /// Enroll a face from an image file path.
  /// Detects the face, extracts landmarks, and stores them.
  static Future<FaceEnrollResult> enrollFace({
    required String imagePath,
    String userName = 'Ahmad Razif',
  }) async {
    try {
      final faces = await detectFaces(imagePath);

      if (faces.isEmpty) {
        return FaceEnrollResult(
          success: false,
          message: 'No face detected. Please ensure your face is clearly visible.',
        );
      }

      if (faces.length > 1) {
        return FaceEnrollResult(
          success: false,
          message: 'Multiple faces detected. Only one face is allowed.',
        );
      }

      final face = faces.first;

      // Liveness check: verify eyes are open (classification)
      if (face.leftEyeOpenProbability != null &&
          face.rightEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.3 &&
            face.rightEyeOpenProbability! < 0.3) {
          return FaceEnrollResult(
            success: false,
            message: 'Please keep your eyes open for enrollment.',
          );
        }
      }

      // Extract and store landmarks
      final landmarks = _extractLandmarks(face);
      final prefs = await SharedPreferences.getInstance();

      final landmarkJson = jsonEncode(landmarks);
      await prefs.setString(_faceLandmarksKey, landmarkJson);
      await prefs.setString(_faceTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_faceNameKey, userName);

      // Also store the old key for backward compat
      final signature = base64Encode(utf8.encode(landmarkJson));
      await prefs.setString(_faceKey, signature);

      return FaceEnrollResult(
        success: true,
        message: 'Face enrolled successfully! ${landmarks.length} landmarks captured.',
        landmarkCount: landmarks.length,
      );
    } catch (e) {
      return FaceEnrollResult(
        success: false,
        message: 'Enrollment error: ${e.toString()}',
      );
    }
  }

  /// Verify a face from a live image against the stored enrollment data.
  static Future<FaceVerifyResult> verifyFace({String? imagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_faceLandmarksKey);

    if (storedJson == null || storedJson.isEmpty) {
      return FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'No face enrolled. Please register first.',
        needsEnrollment: true,
      );
    }

    // SECURITY: No image means camera capture failed — hard reject, no random fallback.
    if (imagePath == null) {
      return FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'Camera capture failed. Please try again.',
        needsEnrollment: false,
      );
    }

    try {
      final faces = await detectFaces(imagePath);

      if (faces.isEmpty) {
        return FaceVerifyResult(
          success: false,
          confidence: 0,
          message: 'No face detected. Please position your face within the frame.',
          needsEnrollment: false,
        );
      }

      final liveFace = faces.first;

      // Liveness check: ensure eyes are open
      if (liveFace.leftEyeOpenProbability != null &&
          liveFace.rightEyeOpenProbability != null) {
        final avgEyeOpen = (liveFace.leftEyeOpenProbability! +
            liveFace.rightEyeOpenProbability!) / 2;
        if (avgEyeOpen < 0.2) {
          return FaceVerifyResult(
            success: false,
            confidence: 0,
            message: 'Liveness check failed. Please open your eyes.',
            needsEnrollment: false,
          );
        }
      }

      // Additional liveness heuristic
      final hasValidSmilingData = liveFace.smilingProbability != null;

      // Extract landmarks from live face
      final liveLandmarks = _extractLandmarks(liveFace);
      final storedLandmarks = Map<String, dynamic>.from(jsonDecode(storedJson));

      // Compare landmarks to calculate similarity
      double totalDiff = 0;
      int matchedPoints = 0;

      for (final key in storedLandmarks.keys) {
        if (liveLandmarks.containsKey(key)) {
          final stored = Map<String, double>.from(storedLandmarks[key]);
          final live = liveLandmarks[key]!;
          final dx = (stored['x']! - live['x']!);
          final dy = (stored['y']! - live['y']!);
          totalDiff += sqrt(dx * dx + dy * dy);
          matchedPoints++;
        }
      }

      if (matchedPoints == 0) {
        return FaceVerifyResult(
          success: false,
          confidence: 0,
          message: 'Unable to compare faces. Landmarks not detected.',
          needsEnrollment: false,
        );
      }

      // Calculate confidence (lower diff = higher confidence)
      final avgDiff = totalDiff / matchedPoints;
      // avgDiff of 0 = perfect match, avgDiff of 0.5 = bad match
      final confidence = (1.0 - (avgDiff * 2.5)).clamp(0.0, 1.0);
      const threshold = 0.60; // 60% match threshold

      return FaceVerifyResult(
        success: confidence >= threshold,
        confidence: confidence,
        message: confidence >= threshold
            ? 'Identity verified (${(confidence * 100).toStringAsFixed(1)}% match, $matchedPoints points)'
            : 'Face mismatch (${(confidence * 100).toStringAsFixed(1)}% confidence). Try again.',
        needsEnrollment: false,
      );
    } catch (e) {
      return FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'Verification error: ${e.toString()}',
        needsEnrollment: false,
      );
    }
  }

  /// Delete the enrolled face data.
  static Future<void> deleteFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_faceKey);
    await prefs.remove(_faceTimestampKey);
    await prefs.remove(_faceNameKey);
    await prefs.remove(_faceLandmarksKey);
  }

  /// Cleanup: call when done with face detection to free resources.
  static void dispose() {
    _faceDetector.close();
  }

  // ─── Legacy compatibility ───
  static Future<bool> isAvailable() async => true;
  static Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    final result = await verifyFace();
    return result.success;
  }
}

class FaceEnrollResult {
  final bool success;
  final String message;
  final int landmarkCount;

  const FaceEnrollResult({
    required this.success,
    required this.message,
    this.landmarkCount = 0,
  });
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
