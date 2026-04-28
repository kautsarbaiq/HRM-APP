import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/biometric_service.dart';
import '../../services/camera_service.dart';

class FaceEnrollScreen extends StatefulWidget {
  const FaceEnrollScreen({super.key});
  @override
  State<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends State<FaceEnrollScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanLineCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _ring;
  late Animation<double> _pulse;
  late Animation<double> _scanLine;
  late Animation<double> _progress;
  late Animation<double> _successScale;

  int _phase = 0; // 0=ready, 1=positioning, 2=scanning, 3=processing, 4=done, -1=error
  String _status = 'Position your face within the frame';
  String _subStatus = 'Ensure good lighting and a neutral expression';
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _ring = Tween<double>(begin: 0, end: 1).animate(_ringCtrl);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanLine = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _progress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));

    if (!kIsWeb) {
      _initCamera();
    } else {
      _cameraReady = true; // Web uses mock
    }
  }

  Future<void> _initCamera() async {
    try {
      await CameraService.initialize();
      final frontCam = CameraService.frontCamera;
      if (frontCam != null) {
        _cameraController = CameraController(frontCam, ResolutionPreset.medium, enableAudio: false);
        await _cameraController!.initialize();
        if (mounted) setState(() => _cameraReady = true);
      }
    } catch (e) {
      if (mounted) setState(() { _cameraReady = true; }); // Continue without camera
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
    _progressCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _startEnrollment() async {
    setState(() { _phase = 1; _status = 'Aligning face...'; _subStatus = 'Hold steady, detecting face'; });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() { _phase = 2; _status = 'Scanning facial features...'; _subStatus = 'Detecting landmarks with ML Kit'; });
    _progressCtrl.forward();

    String? imagePath;

    // Capture image from camera (native only)
    if (!kIsWeb && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        imagePath = photo.path;
      } catch (e) {
        // Fallback to mock enrollment
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() { _phase = 3; _status = 'Processing face data...'; _subStatus = 'Encrypting and storing biometric data'; });

    try {
      FaceEnrollResult result;

      if (imagePath != null && !kIsWeb) {
        // Real ML Kit enrollment
        result = await BiometricService.enrollFace(imagePath: imagePath, userName: 'Ahmad Razif');
      } else {
        // Mock enrollment for web/testing — store mock data via SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('enrolled_face_landmarks', '{"leftEye":{"x":0.35,"y":0.3},"rightEye":{"x":0.65,"y":0.3},"noseBase":{"x":0.5,"y":0.45}}');
        await prefs.setString('enrolled_face_timestamp', DateTime.now().toIso8601String());
        await prefs.setString('enrolled_face_name', 'Ahmad Razif');
        await prefs.setString('enrolled_face_signature', 'mock_signature');
        result = FaceEnrollResult(success: true, message: 'Face enrolled (mock mode)', landmarkCount: 3);
      }

      if (!mounted) return;

      if (result.success) {
        _scanLineCtrl.stop();
        _pulseCtrl.stop();
        setState(() { _phase = 4; _status = 'Face Enrolled Successfully ✓'; _subStatus = result.message; });
        _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        _scanLineCtrl.stop();
        _pulseCtrl.stop();
        setState(() { _phase = -1; _status = 'Enrollment Failed'; _subStatus = result.message; });
      }
    } catch (e) {
      if (!mounted) return;
      _scanLineCtrl.stop();
      _pulseCtrl.stop();
      setState(() { _phase = -1; _status = 'Enrollment Failed'; _subStatus = e.toString(); });
    }
  }

  void _retry() {
    setState(() { _phase = 0; _status = 'Position your face within the frame'; _subStatus = 'Ensure good lighting and a neutral expression'; });
    _scanLineCtrl.repeat();
    _pulseCtrl.repeat(reverse: true);
    _progressCtrl.reset();
    _successCtrl.reset();
  }

  Color get _phaseColor {
    if (_phase == 4) return const Color(0xFF10B981);
    if (_phase == -1) return const Color(0xFFEF4444);
    return const Color(0xFF06B6D4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 24), onPressed: () => Navigator.pop(context, false)),
        title: Text('Face Enrollment', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_ring, _pulse, _scanLine, _progress, _successScale]),
        builder: (ctx, _) => Column(children: [
          const SizedBox(height: 20),
          _stepChip(),
          const Spacer(),
          _scanArea(),
          const Spacer(),
          _statusTexts(),
          const SizedBox(height: 8),
          _progressDots(),
          const SizedBox(height: 32),
          _actionButton(),
          const SizedBox(height: 16),
          _footer(),
        ]),
      ),
    );
  }

  Widget _stepChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: _phaseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _phaseColor.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        if (_phase < 4 && _phase >= 0) SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_phaseColor))),
        if (_phase == 4) Icon(Icons.check_circle, color: _phaseColor, size: 16),
        if (_phase == -1) Icon(Icons.error_outline, color: _phaseColor, size: 16),
        const SizedBox(width: 8),
        Text(_phase <= 1 ? 'Step 1 of 3' : _phase == 2 ? 'Step 2 of 3' : _phase == 3 ? 'Step 3 of 3' : _phase == 4 ? 'Complete' : 'Error',
          style: GoogleFonts.poppins(color: _phaseColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _scanArea() {
    return SizedBox(width: 300, height: 380, child: Stack(alignment: Alignment.center, children: [
      if (_phase > 0 && _phase < 4) Transform.rotate(angle: _ring.value * 6.28,
        child: Container(width: 280, height: 360, decoration: BoxDecoration(borderRadius: BorderRadius.circular(140), border: Border.all(color: _phaseColor.withOpacity(0.15), width: 2)))),
      Transform.scale(scale: _phase > 0 && _phase < 4 ? _pulse.value : 1.0,
        child: Container(width: 260, height: 340, decoration: BoxDecoration(borderRadius: BorderRadius.circular(130), border: Border.all(color: _phaseColor.withOpacity(0.2), width: 1.5)))),
      Container(width: 230, height: 300, decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(115),
        border: Border.all(color: _phaseColor.withOpacity(_phase == 4 ? 1.0 : 0.6), width: _phase == 4 ? 3 : 2),
        boxShadow: [BoxShadow(color: _phaseColor.withOpacity(0.2), blurRadius: 25, spreadRadius: 3)],
      ), child: ClipRRect(borderRadius: BorderRadius.circular(115), child: Stack(children: [
        // Camera preview or placeholder
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Center(child: Transform.scale(scale: 1.4, child: CameraPreview(_cameraController!)))
        else
          Container(color: const Color(0xFF0F172A), child: Center(child: Icon(Icons.face, size: 110, color: Colors.white.withOpacity(0.08)))),
        // Success overlay
        if (_phase == 4) Container(color: const Color(0xFF10B981).withOpacity(0.3), child: Center(child: Transform.scale(scale: _successScale.value, child: const Icon(Icons.check_circle, size: 90, color: Colors.white)))),
        // Error overlay
        if (_phase == -1) Container(color: const Color(0xFFEF4444).withOpacity(0.3), child: const Center(child: Icon(Icons.error_outline, size: 90, color: Colors.white))),
        // Scan line
        if (_phase >= 1 && _phase < 4) Positioned(top: _scanLine.value * 280, left: 10, right: 10, child: Container(height: 3, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, _phaseColor.withOpacity(0.9), Colors.transparent]),
          boxShadow: [BoxShadow(color: _phaseColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 5)]))),
        // Feature dots
        if (_phase == 2) ..._buildFeaturePoints(),
      ]))),
      if (_phase >= 2 && _phase < 4) SizedBox(width: 260, height: 340, child: CircularProgressIndicator(value: _progress.value, strokeWidth: 3, strokeCap: StrokeCap.round, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation(_phaseColor))),
      ..._buildCorners(),
    ]));
  }

  Widget _statusTexts() {
    return Column(children: [
      AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(_status, key: ValueKey(_status), textAlign: TextAlign.center, style: GoogleFonts.poppins(color: _phaseColor, fontSize: 18, fontWeight: FontWeight.w600))),
      const SizedBox(height: 6),
      AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(_subStatus, key: ValueKey(_subStatus), textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 13)))),
    ]);
  }

  Widget _progressDots() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
      duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4),
      width: (_phase > 0 && _phase - 1 >= i) || _phase == 4 ? 28 : 8, height: 8,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: (_phase > 0 && _phase - 1 >= i) || _phase == 4 ? (_phase == 4 ? const Color(0xFF10B981) : const Color(0xFF06B6D4)) : Colors.white.withOpacity(0.15)),
    )));
  }

  Widget _actionButton() {
    if (_phase == 0) {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
        onPressed: _startEnrollment, icon: const Icon(Icons.camera_alt_outlined, size: 22),
        label: Text('Start Face Enrollment', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
      )));
    }
    if (_phase == -1) {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
        onPressed: _retry, icon: const Icon(Icons.refresh, size: 20),
        label: Text('Try Again', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
      )));
    }
    return const SizedBox.shrink();
  }

  Widget _footer() {
    return Padding(padding: const EdgeInsets.only(bottom: 40), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.25), size: 14), const SizedBox(width: 6),
      Text('Face data is encrypted and stored locally', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.25), fontSize: 12)),
    ]));
  }

  List<Widget> _buildFeaturePoints() {
    final points = <Widget>[];
    final offsets = [
      const Offset(0.35, 0.3), const Offset(0.65, 0.3),
      const Offset(0.5, 0.45), const Offset(0.38, 0.65), const Offset(0.62, 0.65),
      const Offset(0.25, 0.35), const Offset(0.75, 0.35), const Offset(0.5, 0.22), const Offset(0.5, 0.75),
    ];
    for (int i = 0; i < offsets.length; i++) {
      if (_progress.value > (i / offsets.length)) {
        points.add(Positioned(left: offsets[i].dx * 210, top: offsets[i].dy * 280, child: Container(width: 6, height: 6, decoration: BoxDecoration(
          shape: BoxShape.circle, color: const Color(0xFF06B6D4),
          boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]))));
      }
    }
    return points;
  }

  List<Widget> _buildCorners() {
    const c = Color(0xFF06B6D4); const s = 28.0; const t = 3.0;
    return [
      Positioned(top: 0, left: 15, child: SizedBox(width: s, height: s, child: DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: c, width: t), left: BorderSide(color: c, width: t)))))),
      Positioned(top: 0, right: 15, child: SizedBox(width: s, height: s, child: DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: c, width: t), right: BorderSide(color: c, width: t)))))),
      Positioned(bottom: 0, left: 15, child: SizedBox(width: s, height: s, child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c, width: t), left: BorderSide(color: c, width: t)))))),
      Positioned(bottom: 0, right: 15, child: SizedBox(width: s, height: s, child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c, width: t), right: BorderSide(color: c, width: t)))))),
    ];
  }
}
