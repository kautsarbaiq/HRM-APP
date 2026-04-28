import 'package:camera/camera.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  
  static Future<void> initialize() async {
    if (_cameras != null) return;
    _cameras = await availableCameras();
  }

  static CameraDescription? get frontCamera {
    if (_cameras == null) return null;
    try {
      return _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      return _cameras!.first;
    }
  }

  static CameraDescription? get backCamera {
    if (_cameras == null) return null;
    try {
      return _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    } catch (e) {
      return _cameras!.first;
    }
  }
}
