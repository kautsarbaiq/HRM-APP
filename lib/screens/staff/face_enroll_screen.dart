import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
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

  @override
  void initState() {
    super.initState();
    _initCamera();
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    setState(() { _phase = 1; _status = 'Aligning face...'; _subStatus = 'Hold steady, detecting landmarks'; });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() { _phase = 2; _status = 'Scanning facial features...'; _subStatus = 'Mapping 128 facial points'; });
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    setState(() { _phase = 3; _status = 'Generating face signature...'; _subStatus = 'Encrypting biometric data'; });

    try {
      // Simulate capturing an image
      // final XFile image = await _cameraController!.takePicture();
      
      await BiometricService.enrollFace(userName: 'Ahmad Razif');
      if (!mounted) return;

      _scanLineCtrl.stop();
      _pulseCtrl.stop();

      setState(() { _phase = 4; _status = 'Face Enrolled Successfully ✓'; _subStatus = 'Your face data is securely stored'; });
      _successCtrl.forward();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _scanLineCtrl.stop();
      _pulseCtrl.stop();
      setState(() { _phase = -1; _status = 'Enrollment Failed'; _subStatus = e.toString(); });
    }
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text('Face Enrollment', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_ring, _pulse, _scanLine, _progress, _successScale]),
        builder: (ctx, _) => Column(children: [
          const SizedBox(height: 20),
          // Instructions chip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _phaseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _phaseColor.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (_phase < 4 && _phase >= 0)
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_phaseColor))),
              if (_phase == 4)
                Icon(Icons.check_circle, color: _phaseColor, size: 16),
              if (_phase == -1)
                Icon(Icons.error_outline, color: _phaseColor, size: 16),
              const SizedBox(width: 8),
              Text(
                _phase == 0 ? 'Step 1 of 3' : _phase == 1 ? 'Step 1 of 3' : _phase == 2 ? 'Step 2 of 3' : _phase == 3 ? 'Step 3 of 3' : _phase == 4 ? 'Complete' : 'Error',
                style: GoogleFonts.poppins(color: _phaseColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          const Spacer(),

          // Face scan area
          SizedBox(width: 300, height: 380, child: Stack(alignment: Alignment.center, children: [
            // Rotating ring
            if (_phase > 0 && _phase < 4)
              Transform.rotate(
                angle: _ring.value * 6.28,
                child: Container(width: 280, height: 360, decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(140),
                  border: Border.all(
                    color: _phaseColor.withOpacity(0.15),
                    width: 2,
                  ),
                )),
              ),

            // Pulsing outer border
            Transform.scale(
              scale: _phase > 0 && _phase < 4 ? _pulse.value : 1.0,
              child: Container(width: 260, height: 340, decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(130),
                border: Border.all(color: _phaseColor.withOpacity(0.2), width: 1.5),
              )),
            ),

            // Main face frame
            Container(width: 230, height: 300, decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(115),
              border: Border.all(
                color: _phaseColor.withOpacity(_phase == 4 ? 1.0 : 0.6),
                width: _phase == 4 ? 3 : 2,
              ),
              boxShadow: [BoxShadow(color: _phaseColor.withOpacity(0.2), blurRadius: 25, spreadRadius: 3)],
            ), child: ClipRRect(borderRadius: BorderRadius.circular(115), child: Stack(children: [
              // Camera Preview
              if (_cameraController != null && _cameraController!.value.isInitialized)
                Center(child: AspectRatio(
                  aspectRatio: 1 / _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ))
              else
                Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),

              // Success overlay
              if (_phase == 4)
                Container(color: const Color(0xFF10B981).withOpacity(0.3), child: Center(
                  child: Transform.scale(scale: _successScale.value, child: const Icon(Icons.check_circle, key: ValueKey('done'), size: 90, color: Colors.white)),
                )),

              // Scan line
              if (_phase >= 1 && _phase < 4)
                Positioned(
                  top: _scanLine.value * 280,
                  left: 10, right: 10,
                  child: Container(height: 3, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, _phaseColor.withOpacity(0.9), Colors.transparent]),
                    boxShadow: [BoxShadow(color: _phaseColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 5)],
                  )),
                ),

              // Feature point dots (during scanning)
              if (_phase == 2) ..._buildFeaturePoints(),
            ]))),

            // Progress ring
            if (_phase >= 2 && _phase < 4)
              SizedBox(width: 260, height: 340, child: CircularProgressIndicator(
                value: _progress.value,
                strokeWidth: 3, strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(_phaseColor),
              )),

            // Corner brackets
            ..._buildCorners(),
          ])),

          const Spacer(),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(_status, key: ValueKey(_status), textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _phaseColor, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(_subStatus, key: ValueKey(_subStatus), textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          ),

          const SizedBox(height: 8),

          // Progress steps
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: (_phase > 0 && _phase - 1 >= i) || _phase == 4 ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: (_phase > 0 && _phase - 1 >= i) || _phase == 4
                  ? (_phase == 4 ? const Color(0xFF10B981) : const Color(0xFF06B6D4))
                  : Colors.white.withOpacity(0.15),
            ),
          ))),

          const SizedBox(height: 32),

          // Action button
          if (_phase == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
                onPressed: _startEnrollment,
                icon: const Icon(Icons.camera_alt_outlined, size: 22),
                label: Text('Start Face Enrollment', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              )),
            ),

          const SizedBox(height: 16),

          // Security footer
          Padding(padding: const EdgeInsets.only(bottom: 40), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.25), size: 14),
            const SizedBox(width: 6),
            Text('Face data is encrypted and stored locally', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.25), fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  List<Widget> _buildFeaturePoints() {
    final points = <Widget>[];
    final offsets = [
      const Offset(0.35, 0.3), const Offset(0.65, 0.3), // eyes
      const Offset(0.5, 0.45), // nose
      const Offset(0.38, 0.65), const Offset(0.62, 0.65), // mouth
      const Offset(0.25, 0.35), const Offset(0.75, 0.35), // temples
      const Offset(0.5, 0.22), // forehead
      const Offset(0.5, 0.75), // chin
    ];

    for (int i = 0; i < offsets.length; i++) {
      final visible = _progress.value > (i / offsets.length);
      if (visible) {
        points.add(Positioned(
          left: offsets[i].dx * 210,
          top: offsets[i].dy * 280,
          child: AnimatedOpacity(
            opacity: visible ? 0.8 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(width: 6, height: 6, decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF06B6D4),
              boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
            )),
          ),
        ));
      }
    }
    return points;
  }

  List<Widget> _buildCorners() {
    const color = Color(0xFF06B6D4);
    const size = 28.0;
    const thickness = 3.0;
    return [
      Positioned(top: 0, left: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: thickness), left: BorderSide(color: color, width: thickness)))))),
      Positioned(top: 0, right: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: thickness), right: BorderSide(color: color, width: thickness)))))),
      Positioned(bottom: 0, left: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: thickness), left: BorderSide(color: color, width: thickness)))))),
      Positioned(bottom: 0, right: 15, child: SizedBox(width: size, height: size, child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: thickness), right: BorderSide(color: color, width: thickness)))))),
    ];
  }
}
