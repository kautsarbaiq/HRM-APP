import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_indicator.dart';
import 'face_scan_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with TickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;
  bool _isScanning = false;
  bool _isCheckedIn = false;
  final List<Map<String, dynamic>> _logs = [
    {'type': 'Check In', 'time': '08:32 AM', 'icon': Icons.login, 'color': const Color(0xFF10B981)},
    {'type': 'Check Out', 'time': '05:45 PM', 'icon': Icons.logout, 'color': const Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _scanCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  void _startScan({required bool isCheckOut}) async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FaceScanScreen(onSuccess: () {}),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    if (result == true && mounted) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      
      setState(() {
        if (isCheckOut) {
          _isCheckedIn = false;
          _logs.add({'type': 'Check Out', 'time': timeStr, 'icon': Icons.logout, 'color': const Color(0xFFEF4444)});
        } else {
          _isCheckedIn = true;
          _logs.add({'type': 'Check In', 'time': timeStr, 'icon': Icons.login, 'color': const Color(0xFF10B981)});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${isCheckOut ? 'Check-out' : 'Check-in'} successful! ✓', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isCheckOut ? const Color(0xFFEF4444) : const Color(0xFF10B981), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Smart Check-in', style: GoogleFonts.poppins(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Face verification required for attendance', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 24),
        _cameraPreview(),
        const SizedBox(height: 20),
        _geofenceStatus(),
        const SizedBox(height: 20),
        _actionButtons(),
        const SizedBox(height: 24),
        _todayLog(),
      ]),
    ));
  }

  Widget _cameraPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(padding: const EdgeInsets.all(8), child: AspectRatio(aspectRatio: 3 / 4,
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          gradient: RadialGradient(
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
            stops: const [0, 0.6, 1]))),
        Center(child: Container(width: 140, height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(70), border: Border.all(color: (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(0.2), width: 1)),
          child: Icon(Icons.face, size: 80, color: (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(0.2)))),
        Positioned(bottom: 16, left: 0, right: 0, child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isCheckedIn ? const Color(0xFF10B981).withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(20)),
          child: Text(
            _isCheckedIn ? '✓ Face verified' : 'Ready for verification',
            style: GoogleFonts.poppins(color: _isCheckedIn ? const Color(0xFF059669) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), fontSize: 13, fontWeight: FontWeight.w500)),
        ))),
      ]))));
  }

  List<Widget> _corners() {
    const c = Color(0xFF06B6D4); const s = 30.0; const w = 3.0;
    Widget cr(bool tl, bool tr, bool bl, bool br) => Container(width: s, height: s, decoration: BoxDecoration(border: Border(
      top: (tl || tr) ? BorderSide(color: c, width: w) : BorderSide.none,
      bottom: (bl || br) ? BorderSide(color: c, width: w) : BorderSide.none,
      left: (tl || bl) ? BorderSide(color: c, width: w) : BorderSide.none,
      right: (tr || br) ? BorderSide(color: c, width: w) : BorderSide.none)));
    return [
      Positioned(top: 20, left: 20, child: cr(true, false, false, false)),
      Positioned(top: 20, right: 20, child: cr(false, true, false, false)),
      Positioned(bottom: 50, left: 20, child: cr(false, false, true, false)),
      Positioned(bottom: 50, right: 20, child: cr(false, false, false, true)),
    ];
  }

  Widget _geofenceStatus() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        const GlowIndicator(isActive: true, label: 'In Range'),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Office Area', style: GoogleFonts.poppins(color: onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('Geofencing Active', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 12)),
        ]),
      ]));
  }

  Widget _actionButtons() {
    return Column(children: [
      if (!_isCheckedIn) _btn(label: 'Check In Now', color1: const Color(0xFF22D3EE), color2: const Color(0xFF06B6D4), isOut: false),
      if (_isCheckedIn) _slideBtn(),
    ]);
  }

  double _slidePos = 0;
  Widget _slideBtn() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity, height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(builder: (ctx, box) {
        final maxW = box.maxWidth - 64;
        return Stack(children: [
          Center(child: Text('Slide to Check Out', style: GoogleFonts.poppins(color: onSurface.withOpacity(0.4), fontSize: 15, fontWeight: FontWeight.w600))),
          Positioned(left: _slidePos, child: GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() => _slidePos = (_slidePos + d.delta.dx).clamp(0, maxW)),
            onHorizontalDragEnd: (d) {
              if (_slidePos > maxW * 0.8) {
                _startScan(isCheckOut: true);
              }
              setState(() => _slidePos = 0);
            },
            child: Container(width: 64, height: 64, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFF87171), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20)),
          )),
        ]);
      }),
    );
  }

  Widget _btn({required String label, required Color color1, required Color color2, required bool isOut}) {
    return AnimatedBuilder(animation: _pulseAnim, builder: (ctx, child) =>
      Transform.scale(scale: _pulseAnim.value, child: child),
      child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: () => _startScan(isCheckOut: isOut),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: color2.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Container(alignment: Alignment.center, height: 56,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
        ),
      )));
  }

  Widget _todayLog() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text("Attendance Activity", style: GoogleFonts.poppins(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700))),
      if (_logs.isEmpty) GlassCard(child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          Icon(Icons.history, color: onSurfaceVariant.withOpacity(0.5), size: 32),
          const SizedBox(height: 8),
          Text('No activity recorded yet', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 14)),
        ]))),
      ..._logs.reversed.map((log) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: log['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(log['icon'], color: log['color'], size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log['type'], style: GoogleFonts.poppins(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('Success • Face Verified', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(log['time'], style: GoogleFonts.poppins(color: onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Today', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 11)),
          ]),
        ])),
      )),
    ]);
  }
}
