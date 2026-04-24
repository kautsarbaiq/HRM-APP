import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut));
    _fadeCtrl.forward(); _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _scaleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFF1E293B), Color(0xFF0F172A)]),
        ),
        child: Center(child: AnimatedBuilder(
          animation: Listenable.merge([_fade, _scale]),
          builder: (ctx, child) => Opacity(opacity: _fade.value, child: Transform.scale(scale: _scale.value, child: child)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
                boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
              ),
              child: const Icon(Icons.fingerprint, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]).createShader(b),
              child: Text('ESS', style: GoogleFonts.poppins(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: 8)),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🇲🇾 ', style: GoogleFonts.poppins(fontSize: 16)),
              Text('Malaysia', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14, letterSpacing: 2)),
            ]),
          ]),
        )),
      ),
    );
  }
}
