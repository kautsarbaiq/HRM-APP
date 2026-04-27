import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_gradient_bg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'ahmad.razif@syarikat.com.my');
  final _passCtrl = TextEditingController(text: '••••••••');
  bool _obscure = true;
  bool _isBioScanning = false;
  late AnimationController _bioCtrl;
  late Animation<double> _bioScale;

  @override
  void initState() {
    super.initState();
    _bioCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _bioScale = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _bioCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _bioCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  void _login() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _biometricLogin() {
    setState(() => _isBioScanning = true);
    _bioCtrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      _bioCtrl.stop();
      if (mounted) {
        setState(() => _isBioScanning = false);
        _login();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: MeshGradientBg(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Company Logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 8))],
                  ),
                  child: ClipOval(child: Image.asset('assets/phh-icon-removebg-preview.png', fit: BoxFit.cover)),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF06B6D4), const Color(0xFF8B5CF6)]
                      : [const Color(0xFF06B6D4), const Color(0xFF06B6D4)],
                  ).createShader(b),
                  child: Text('PHH ERP', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
                const SizedBox(height: 40),
                // Login card
                GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Welcome Back', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('Sign in to continue', style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
                    const SizedBox(height: 24),
                    // Email
                    Text('Email', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF06B6D4).withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _emailCtrl,
                        style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter your email', hintStyle: GoogleFonts.poppins(color: isDark ? const Color(0xFF475569) : const Color(0xFF64748B)),
                          prefixIcon: Icon(Icons.email_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF06B6D4), size: 20),
                          border: InputBorder.none, contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password
                    Text('Password', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF06B6D4).withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _passCtrl, obscureText: _obscure,
                        style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter password', hintStyle: GoogleFonts.poppins(color: isDark ? const Color(0xFF475569) : const Color(0xFF64748B)),
                          prefixIcon: Icon(Icons.lock_outline, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF06B6D4), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF06B6D4), size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          border: InputBorder.none, contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign in button
                    SizedBox(width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: isDark 
                                ? [const Color(0xFF06B6D4), const Color(0xFF8B5CF6)]
                                : [const Color(0xFF06B6D4), const Color(0xFF06B6D4)],
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                            ],
                          ),
                          child: Container(alignment: Alignment.center, child: Text('Sign In', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                // Biometric login
                Text('or sign in with', style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _bioScale,
                  builder: (ctx, child) => Transform.scale(scale: _isBioScanning ? _bioScale.value : 1.0, child: child),
                  child: GestureDetector(
                    onTap: _isBioScanning ? null : _biometricLogin,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.transparent,
                        border: Border.all(
                          color: _isBioScanning 
                            ? (isDark ? const Color(0xFF06B6D4) : const Color(0xFF06B6D4)) 
                            : (isDark ? const Color(0xFF334155) : const Color(0xFF06B6D4).withOpacity(0.5)), 
                          width: _isBioScanning ? 2 : 1
                        ),
                        boxShadow: _isBioScanning ? [BoxShadow(color: isDark ? const Color(0xFF06B6D4).withOpacity(0.3) : const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 20, spreadRadius: 4)] : null,
                      ),
                      child: Icon(Icons.fingerprint, color: _isBioScanning ? (isDark ? const Color(0xFF06B6D4) : const Color(0xFF06B6D4)) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF06B6D4)), size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_isBioScanning ? 'Scanning...' : 'Touch to authenticate', style: GoogleFonts.poppins(color: _isBioScanning ? (isDark ? const Color(0xFF06B6D4) : const Color(0xFF0F172A)) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), fontSize: 12)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
