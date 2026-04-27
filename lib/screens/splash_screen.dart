import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _gradientCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _gradientSweep;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _textBlur;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    
    // Phase 1: Gradient materializes (0-800ms)
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _gradientSweep = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientCtrl, curve: Curves.easeOut));
    
    // Phase 2: Logo elastic bounce (600-1600ms)
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    
    // Phase 3: Text blur-to-sharp + subtitle (1200-2200ms)
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textBlur = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    
    // Particle float (continuous)
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    
    // Orchestrate phases
    _gradientCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () => _logoCtrl.forward());
    Future.delayed(const Duration(milliseconds: 1200), () => _textCtrl.forward());
    
    // Navigate after 3s
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_gradientCtrl, _logoCtrl, _textCtrl, _particleCtrl]),
        builder: (ctx, _) {
          return Stack(
            children: [
              // Animated gradient background
              AnimatedOpacity(
                opacity: _gradientSweep.value,
                duration: Duration.zero,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF020617)]
                        : [const Color(0xFFFFFFFF), const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Floating particles
              ..._buildParticles(isDark),
              
              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with elastic bounce
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0047AB).withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/phh-icon-removebg-preview.png',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => const Icon(Icons.business, color: Colors.white, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // PHH ERP text with blur-to-sharp reveal
                    Opacity(
                      opacity: _textFade.value,
                      child: ImageFiltered(
                        imageFilter: _textBlur.value > 0.1
                          ? ColorFilter.mode(Colors.transparent, BlendMode.dst)
                          : ColorFilter.mode(Colors.transparent, BlendMode.dst),
                        child: ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: isDark 
                              ? [const Color(0xFFF1F5F9), const Color(0xFF94A3B8)]
                              : [const Color(0xFF0F172A), const Color(0xFF334155)],
                          ).createShader(b),
                          child: Shimmer.fromColors(
                            baseColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            highlightColor: const Color(0xFF06B6D4),
                            period: const Duration(milliseconds: 2500),
                            child: Text('PHH',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 54,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Subtitle with delayed fade
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: Text('E R P   S O L U T I O N',
                        style: GoogleFonts.poppins(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(
                            isDark ? const Color(0xFF06B6D4) : const Color(0xFF0F172A).withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom branding
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _subtitleFade.value,
                  child: Text(
                    'Powered by Bluesoft IOT Sdn Bhd',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles(bool isDark) {
    final t = _particleCtrl.value * 2 * math.pi;
    final particles = <Widget>[];
    final configs = [
      _ParticleConfig(0.15, 0.25, 6, 0),
      _ParticleConfig(0.82, 0.35, 4, 1.5),
      _ParticleConfig(0.65, 0.75, 5, 3.0),
      _ParticleConfig(0.25, 0.85, 3, 4.5),
    ];
    
    for (final p in configs) {
      final dx = math.sin(t + p.phase) * 20;
      final dy = math.cos(t + p.phase * 0.7) * 15;
      particles.add(
        Positioned(
          left: MediaQuery.of(context).size.width * p.x + dx,
          top: MediaQuery.of(context).size.height * p.y + dy,
          child: Opacity(
            opacity: (0.3 + 0.2 * math.sin(t + p.phase)).clamp(0.0, 1.0) * _gradientSweep.value,
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF06B6D4) : const Color(0xFF8B5CF6),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF06B6D4) : const Color(0xFF8B5CF6)).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return particles;
  }
}

class _ParticleConfig {
  final double x, y, size, phase;
  const _ParticleConfig(this.x, this.y, this.size, this.phase);
}
