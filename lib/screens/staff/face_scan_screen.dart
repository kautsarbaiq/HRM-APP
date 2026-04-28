import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../../services/biometric_service.dart';
import '../../services/camera_service.dart';
import 'face_enroll_screen.dart';

class FaceScanScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const FaceScanScreen({super.key, this.onSuccess});
  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _cornerCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _scanLine;
  late Animation<double> _pulse;
  late Animation<double> _corners;
  late Animation<double> _progress;

  String _status = 'Position your face within the frame';
  String _confidence = '';
  int _phase = 0; // 0=ready, 1=checking, 2=verifying, 3=verified, -1=failed, -2=needs enrollment

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanLine = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _cornerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _corners = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _cornerCtrl, curve: Curves.easeInOut));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _progress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _startScanSequence();
  }

  Future<void> _initCamera() async {
    await CameraService.initialize();
    final frontCam = CameraService.frontCamera;
    if (frontCam != null) {
      _cameraController = CameraController(frontCam, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  void _startScanSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Phase 1: Check if face is enrolled
    setState(() { _phase = 1; _status = 'Checking face enrollment...'; });
    _cornerCtrl.forward();

    final isEnrolled = await BiometricService.isFaceEnrolled();
    if (!mounted) return;

    if (!isEnrolled) {
      _scanLineCtrl.stop();
      _pulseCtrl.stop();
      setState(() {
        _phase = -2;
        _status = 'No face data found';
        _confidence = 'You need to register your face first';
      });
      return;
    }

    // Phase 2: Verify face
    setState(() { _phase = 2; _status = 'Verifying identity...'; });
    _progressCtrl.forward();

    final result = await BiometricService.verifyFace();
    if (!mounted) return;
    _scanLineCtrl.stop();
    _pulseCtrl.stop();

    if (result.success) {
      setState(() {
        _phase = 3;
        _status = 'Identity Verified ✓';
        _confidence = '${(result.confidence * 100).toStringAsFixed(1)}% match confidence';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _phase = -1;
        _status = 'Verification failed';
        _confidence = result.message;
      });
    }
  }

  void _retryAuthentication() {
    setState(() { _phase = 0; _status = 'Position your face within the frame'; _confidence = ''; });
    _scanLineCtrl.repeat();
    _pulseCtrl.repeat(reverse: true);
    _cornerCtrl.reset();
    _progressCtrl.reset();
    _startScanSequence();
  }

  void _goToEnrollment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FaceEnrollScreen()),
    );
    if (result == true && mounted) {
      _retryAuthentication();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _cornerCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Color get _phaseColor {
    if (_phase == 3) return const Color(0xFF10B981);
    if (_phase == -1) return const Color(0xFFEF4444);
    if (_phase == -2) return const Color(0xFFF59E0B);
    return const Color(0xFF06B6D4);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 24), onPressed: () => Navigator.pop(context, false)),
        title: Text('Face Recognition', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_scanLine, _pulse, _corners, _progress]),
        builder: (ctx, _) {
          return Column(children: [
            const Spacer(),
            SizedBox(width: 280, height: 360, child: Stack(alignment: Alignment.center, children: [
              Container(width: 260 * _pulse.value, height: 340 * _pulse.value, decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(130),
                border: Border.all(color: _phaseColor.withOpacity(_phase == 3 || _phase < 0 ? 0.3 : 0.15 * _pulse.value), width: 2),
              )),
              Container(width: 220, height: 290, decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(110),
                border: Border.all(color: _phaseColor.withOpacity(_phase == 3 ? 1.0 : 0.6 + 0.4 * _pulse.value), width: _phase == 3 ? 3 : 2),
                boxShadow: [BoxShadow(color: _phaseColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
              ), child: ClipRRect(borderRadius: BorderRadius.circular(110), child: Stack(children: [
                // Camera Preview
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  Center(child: AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ))
                else
                  Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),

                // Overlay for status
                if (_phase == 3) Container(color: const Color(0xFF10B981).withOpacity(0.3), child: const Center(child: Icon(Icons.check_circle, size: 80, color: Colors.white))),
                if (_phase == -1) Container(color: const Color(0xFFEF4444).withOpacity(0.3), child: const Center(child: Icon(Icons.error_outline, size: 80, color: Colors.white))),
                if (_phase == -2) Container(color: const Color(0xFFF59E0B).withOpacity(0.3), child: const Center(child: Icon(Icons.person_add_alt_1, size: 80, color: Colors.white))),

                if (_phase >= 0 && _phase < 3) Positioned(top: _scanLine.value * 270, left: 10, right: 10, child: Container(height: 2, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF06B6D4).withOpacity(0.8), Colors.transparent]),
                  boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 12, spreadRadius: 4)],
                ))),
              ]))),
              ..._buildCorners(),
              if (_phase >= 2 && _phase != -1 && _phase != -2) SizedBox(width: 250, height: 330, child: CircularProgressIndicator(
                value: _phase == 3 ? 1.0 : _progress.value, strokeWidth: 3, strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation(_phase == 3 ? const Color(0xFF10B981) : const Color(0xFF06B6D4)),
              )),
            ])),
            const SizedBox(height: 40),
            AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(_status, key: ValueKey(_status), style: GoogleFonts.poppins(color: _phaseColor, fontSize: 16, fontWeight: FontWeight.w500))),
            if (_confidence.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_confidence, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _phase > i ? 24 : 8, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
              color: _phase > i ? (_phase == 3 ? const Color(0xFF10B981) : const Color(0xFF06B6D4)) : Colors.white.withOpacity(0.2)),
            ))),
            const SizedBox(height: 24),

            if (_phase == -1) Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
              onPressed: _retryAuthentication, icon: const Icon(Icons.refresh, size: 20),
              label: Text('Try Again', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            ))),

            if (_phase == -2) Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(children: [
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
                onPressed: _goToEnrollment,
                icon: const Icon(Icons.face_retouching_natural, size: 22),
                label: Text('Register Face Now', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                ),
              )),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 14)),
              ),
            ])),

            const Spacer(flex: 2),
            Padding(padding: const EdgeInsets.only(bottom: 40), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.3), size: 14), const SizedBox(width: 6),
              Text('Secured with in-app face verification', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 12)),
            ])),
          ]);
        },
      ),
    );
  }

  List<Widget> _buildCorners() {
    final size = 30.0 * _corners.value;
    const color = Color(0xFF06B6D4);
    const thickness = 3.0;
    return [
      Positioned(top: 0, left: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: thickness), left: BorderSide(color: color, width: thickness)))))),
      Positioned(top: 0, right: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: thickness), right: BorderSide(color: color, width: thickness)))))),
      Positioned(bottom: 0, left: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: thickness), left: BorderSide(color: color, width: thickness)))))),
      Positioned(bottom: 0, right: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: thickness), right: BorderSide(color: color, width: thickness)))))),
    ];
  }
}
