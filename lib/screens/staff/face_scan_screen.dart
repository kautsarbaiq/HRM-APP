import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/biometric_service.dart';

class FaceScanScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const FaceScanScreen({super.key, this.onSuccess});
  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> with TickerProviderStateMixin {
  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _cornerCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _scanLine;
  late Animation<double> _pulse;
  late Animation<double> _corners;
  late Animation<double> _progress;

  String _status = 'Position your face within the frame';
  int _phase = 0; // 0=ready, 1=aligning, 2=scanning, 3=verified

  @override
  void initState() {
    super.initState();
    
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    _cornerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _corners = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _cornerCtrl, curve: Curves.easeInOut));
    
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    
    _startScanSequence();
  }

  void _startScanSequence() async {
    // Phase 1: Aligning (0.5s)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() { _phase = 1; _status = 'Aligning face...'; });
    _cornerCtrl.forward();
    
    // Phase 2: Scanning (1.5s)
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() { _phase = 2; _status = 'Scanning biometrics...'; });
    _progressCtrl.forward();
    
    // Authenticate via service
    final success = await BiometricService.authenticate();
    
    if (!mounted) return;
    _scanLineCtrl.stop();
    _pulseCtrl.stop();
    
    if (success) {
      setState(() { _phase = 3; _status = 'Identity Verified ✓'; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() { _status = 'Verification failed. Try again.'; });
    }
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _cornerCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text('Face Recognition', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_scanLine, _pulse, _corners, _progress]),
        builder: (ctx, _) {
          return Column(
            children: [
              const Spacer(),
              
              // Face scanning frame
              SizedBox(
                width: 280,
                height: 360,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow pulse
                    Container(
                      width: 260 * _pulse.value,
                      height: 340 * _pulse.value,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(130),
                        border: Border.all(
                          color: _phase == 3
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFF06B6D4).withOpacity(0.15 * _pulse.value),
                          width: 2,
                        ),
                      ),
                    ),
                    
                    // Main oval frame
                    Container(
                      width: 220,
                      height: 290,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(110),
                        border: Border.all(
                          color: _phase == 3
                            ? const Color(0xFF10B981)
                            : const Color(0xFF06B6D4).withOpacity(0.6 + 0.4 * _pulse.value),
                          width: _phase == 3 ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_phase == 3 ? const Color(0xFF10B981) : const Color(0xFF06B6D4))
                                .withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(110),
                        child: Stack(
                          children: [
                            // Face silhouette
                            Center(
                              child: Icon(
                                _phase == 3 ? Icons.check_circle : Icons.face,
                                size: _phase == 3 ? 80 : 100,
                                color: _phase == 3
                                  ? const Color(0xFF10B981).withOpacity(0.8)
                                  : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            
                            // Scanning line
                            if (_phase < 3) Positioned(
                              top: _scanLine.value * 270,
                              left: 10, right: 10,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    const Color(0xFF06B6D4).withOpacity(0.8),
                                    Colors.transparent,
                                  ]),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF06B6D4).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Corner brackets
                    ..._buildCorners(),
                    
                    // Progress ring
                    if (_phase >= 2) SizedBox(
                      width: 250,
                      height: 330,
                      child: CircularProgressIndicator(
                        value: _phase == 3 ? 1.0 : _progress.value,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                          _phase == 3 ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _status,
                  key: ValueKey(_status),
                  style: GoogleFonts.poppins(
                    color: _phase == 3 ? const Color(0xFF10B981) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Phase indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _phase > i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _phase > i
                      ? (_phase == 3 ? const Color(0xFF10B981) : const Color(0xFF06B6D4))
                      : Colors.white.withOpacity(0.2),
                  ),
                )),
              ),
              
              const Spacer(flex: 2),
              
              // Security note
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.3), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Secured with biometric encryption',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCorners() {
    final size = 30.0 * _corners.value;
    const color = Color(0xFF06B6D4);
    const thickness = 3.0;
    
    return [
      // Top-left
      Positioned(top: 0, left: 15,
        child: SizedBox(width: size, height: size,
          child: DecoratedBox(decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          )))),
      // Top-right
      Positioned(top: 0, right: 15,
        child: SizedBox(width: size, height: size,
          child: DecoratedBox(decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          )))),
      // Bottom-left
      Positioned(bottom: 0, left: 15,
        child: SizedBox(width: size, height: size,
          child: DecoratedBox(decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          )))),
      // Bottom-right
      Positioned(bottom: 0, right: 15,
        child: SizedBox(width: size, height: size,
          child: DecoratedBox(decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          )))),
    ];
  }
}
