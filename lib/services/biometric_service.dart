import 'dart:convert';
import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// BiometricService — Real face recognition using:
/// 1. Google ML Kit: Face detection + bounding box + liveness checks
/// 2. TensorFlow Lite + MobileFaceNet: 192-D face embedding extraction
/// 3. Euclidean Distance: Identity comparison via mathematical vector distance
///
/// NO Random(), NO mock, NO simulation. Real AI verification only.
class BiometricService {
  static const _faceEmbeddingKey = 'enrolled_face_embedding_v2';
  static const _faceTimestampKey = 'enrolled_face_timestamp';
  static const _faceNameKey = 'enrolled_face_name';
  static const _modelPath = 'assets/model/mobilefacenet.tflite';

  // TFLite model specs
  static const int _inputSize = 112; // 112x112 input
  static const int _embeddingSize = 192; // 192-D output vector
  static const double _verifyThreshold = 0.75; // Tightened from 1.0 to 0.75 for better security

  static Interpreter? _interpreter;

  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: false, // Not needed for embedding — save CPU
      enableClassification: true, // Needed for liveness (eye open, smile)
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  // ─── Model Management ────────────────────────────────────────────

  /// Initialize the TFLite interpreter from bundled asset.
  static Future<void> _loadModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      debugPrint('[BiometricService] MobileFaceNet model loaded successfully');
      debugPrint('[BiometricService] Input: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('[BiometricService] Output: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      debugPrint('[BiometricService] Failed to load model: $e');
      rethrow;
    }
  }

  // ─── Face Detection ──────────────────────────────────────────────

  /// Detect faces from an image file using ML Kit.
  static Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  // ─── Liveness Detection ──────────────────────────────────────────

  /// Perform liveness checks using ML Kit classification data.
  /// Returns null if alive, or an error message if failed.
  static String? _checkLiveness(Face face) {
    // Check 1: Eyes must be open (anti-photo attack)
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final avgEyeOpen = (face.leftEyeOpenProbability! +
          face.rightEyeOpenProbability!) / 2;
      if (avgEyeOpen < 0.40) { // Tightened from 0.25 to 0.40
        return 'Liveness failed: Please open your eyes wider.';
      }
    }

    // Check 2: Pose check — must face camera directly
    // headEulerAngleY: rotation around vertical axis (turning left/right)
    // headEulerAngleZ: rotation around axis pointing towards camera (tilting)
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 15) {
      return 'Positioning: Please face the camera directly.';
    }
    if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 15) {
      return 'Positioning: Please keep your head straight.';
    }

    // Check 3: Face must have valid classification data
    if (face.leftEyeOpenProbability == null &&
        face.rightEyeOpenProbability == null &&
        face.smilingProbability == null) {
      return 'Liveness failed: Unable to analyze facial features.';
    }

    return null; // Passed all liveness checks
  }

  // ─── Image Preprocessing (runs in Isolate via compute()) ─────────

  /// Top-level function for compute() — must be static/top-level.
  /// Receives image bytes + bounding box data, returns normalized float array.
  static List<double> _preprocessInIsolate(Map<String, dynamic> params) {
    final Uint8List imageBytes = params['imageBytes'];
    final int left = params['left'];
    final int top = params['top'];
    final int width = params['width'];
    final int height = params['height'];

    // Decode the full image
    final fullImage = img.decodeImage(imageBytes);
    if (fullImage == null) return [];

    // Crop face region from bounding box (with safety clamp)
    final cropLeft = left.clamp(0, fullImage.width - 1);
    final cropTop = top.clamp(0, fullImage.height - 1);
    final cropWidth = width.clamp(1, fullImage.width - cropLeft);
    final cropHeight = height.clamp(1, fullImage.height - cropTop);

    final cropped = img.copyCrop(
      fullImage,
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
    );

    // Resize to model input size (112x112)
    final resized = img.copyResize(
      cropped,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Float32 with MobileFaceNet normalization: (pixel - 127.5) / 127.5
    final List<double> floatValues = [];
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        floatValues.add((pixel.r.toDouble() - 127.5) / 127.5);
        floatValues.add((pixel.g.toDouble() - 127.5) / 127.5);
        floatValues.add((pixel.b.toDouble() - 127.5) / 127.5);
      }
    }

    return floatValues;
  }

  /// Preprocess face image for TFLite inference.
  /// Uses compute() to run on a separate isolate — UI stays smooth.
  static Future<List<double>> _preprocessFace(String imagePath, Face face) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final box = face.boundingBox;

    final result = await compute(_preprocessInIsolate, {
      'imageBytes': imageBytes,
      'left': box.left.toInt(),
      'top': box.top.toInt(),
      'width': box.width.toInt(),
      'height': box.height.toInt(),
    });

    return result;
  }

  // ─── Embedding Extraction ────────────────────────────────────────

  /// Run TFLite inference to extract 192-D face embedding vector.
  static Future<List<double>> _getEmbedding(List<double> preprocessedInput) async {
    await _loadModel();
    if (_interpreter == null) {
      throw Exception('TFLite model not loaded');
    }

    // Reshape flat list to [1, 112, 112, 3] tensor
    final input = preprocessedInput
        .reshape([1, _inputSize, _inputSize, 3]);

    // Prepare output buffer [1, 192]
    final output = List.filled(_embeddingSize, 0.0).reshape([1, _embeddingSize]);

    // Run inference
    _interpreter!.run(input, output);

    // Extract embedding vector
    return List<double>.from(output[0]);
  }

  // ─── Distance Calculation ────────────────────────────────────────

  /// Calculate Euclidean distance between two embedding vectors.
  /// Lower distance = more similar faces.
  /// Same person: typically < 1.0
  /// Different person: typically > 1.0
  static double _euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  // ─── Public API ──────────────────────────────────────────────────

  /// Check if a face has been enrolled.
  static Future<bool> isFaceEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_faceEmbeddingKey) &&
        prefs.getString(_faceEmbeddingKey)!.isNotEmpty;
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

  /// Enroll a face: detect → liveness → crop → embed → store.
  static Future<FaceEnrollResult> enrollFace({
    required String imagePath,
    String userName = 'Ahmad Razif',
  }) async {
    try {
      // Step 1: Detect face with ML Kit
      final faces = await detectFaces(imagePath);

      if (faces.isEmpty) {
        return const FaceEnrollResult(
          success: false,
          message: 'No face detected. Please ensure your face is clearly visible.',
        );
      }

      if (faces.length > 1) {
        return const FaceEnrollResult(
          success: false,
          message: 'Multiple faces detected. Only one face is allowed.',
        );
      }

      final face = faces.first;

      // Step 2: Liveness check
      final livenessError = _checkLiveness(face);
      if (livenessError != null) {
        return FaceEnrollResult(success: false, message: livenessError);
      }

      // Step 3: Preprocess image in isolate (crop + resize + normalize)
      final preprocessed = await _preprocessFace(imagePath, face);
      if (preprocessed.isEmpty) {
        return const FaceEnrollResult(
          success: false,
          message: 'Failed to process face image.',
        );
      }

      // Step 4: Extract embedding via TFLite
      final embedding = await _getEmbedding(preprocessed);

      // Step 5: Store embedding in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final embeddingJson = jsonEncode(embedding);
      await prefs.setString(_faceEmbeddingKey, embeddingJson);
      await prefs.setString(_faceTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_faceNameKey, userName);

      debugPrint('[BiometricService] Enrollment complete: ${embedding.length}-D vector stored');

      return FaceEnrollResult(
        success: true,
        message: 'Face enrolled! ${embedding.length}-D AI embedding captured.',
        landmarkCount: embedding.length,
      );
    } catch (e) {
      debugPrint('[BiometricService] Enrollment error: $e');
      return FaceEnrollResult(
        success: false,
        message: 'Enrollment error: ${e.toString()}',
      );
    }
  }

  /// Verify a face: detect → liveness → crop → embed → compare.
  static Future<FaceVerifyResult> verifyFace({String? imagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_faceEmbeddingKey);

    if (storedJson == null || storedJson.isEmpty) {
      return const FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'No face enrolled. Please register first.',
        needsEnrollment: true,
      );
    }

    // SECURITY: No image = hard reject
    if (imagePath == null) {
      return const FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'Camera capture failed. Please try again.',
        needsEnrollment: false,
      );
    }

    try {
      // Step 1: Detect face with ML Kit
      final faces = await detectFaces(imagePath);

      if (faces.isEmpty) {
        return const FaceVerifyResult(
          success: false,
          confidence: 0,
          message: 'No face detected. Please position your face within the frame.',
          needsEnrollment: false,
        );
      }

      final liveFace = faces.first;

      // Step 2: Liveness check
      final livenessError = _checkLiveness(liveFace);
      if (livenessError != null) {
        return FaceVerifyResult(
          success: false,
          confidence: 0,
          message: livenessError,
          needsEnrollment: false,
        );
      }

      // Step 3: Preprocess in isolate
      final preprocessed = await _preprocessFace(imagePath, liveFace);
      if (preprocessed.isEmpty) {
        return const FaceVerifyResult(
          success: false,
          confidence: 0,
          message: 'Failed to process face image.',
          needsEnrollment: false,
        );
      }

      // Step 4: Extract embedding via TFLite
      final liveEmbedding = await _getEmbedding(preprocessed);

      // Step 5: Load stored embedding
      final storedEmbedding = List<double>.from(jsonDecode(storedJson));

      // Step 6: Compare using Euclidean Distance
      final distance = _euclideanDistance(liveEmbedding, storedEmbedding);

      // Convert distance to confidence percentage (for UI display)
      // Distance 0 = 100% match, distance 2.0 = 0% match
      final confidence = (1.0 - (distance / 2.0)).clamp(0.0, 1.0);
      final isMatch = distance < _verifyThreshold;

      debugPrint('[BiometricService] Verify: distance=$distance, confidence=${(confidence * 100).toStringAsFixed(1)}%, match=$isMatch');

      return FaceVerifyResult(
        success: isMatch,
        confidence: confidence,
        message: isMatch
            ? 'Identity verified ✓ (${(confidence * 100).toStringAsFixed(1)}% match, dist: ${distance.toStringAsFixed(2)})'
            : 'Face mismatch (${(confidence * 100).toStringAsFixed(1)}% confidence, dist: ${distance.toStringAsFixed(2)}). Access denied.',
        needsEnrollment: false,
      );
    } catch (e) {
      debugPrint('[BiometricService] Verification error: $e');
      return FaceVerifyResult(
        success: false,
        confidence: 0,
        message: 'Verification error: ${e.toString()}',
        needsEnrollment: false,
      );
    }
  }

  /// Delete enrolled face data.
  static Future<void> deleteFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_faceEmbeddingKey);
    await prefs.remove(_faceTimestampKey);
    await prefs.remove(_faceNameKey);
    // Also clean up old legacy keys if they exist
    await prefs.remove('enrolled_face_signature');
    await prefs.remove('enrolled_face_landmarks');
  }

  /// Cleanup TFLite resources.
  static void dispose() {
    _faceDetector.close();
    _interpreter?.close();
    _interpreter = null;
  }

  // ─── Legacy compatibility ────────────────────────────────────────
  static Future<bool> isAvailable() async => true;
  static Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    final result = await verifyFace();
    return result.success;
  }
}

// ─── Result Classes (unchanged API contract) ─────────────────────

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
