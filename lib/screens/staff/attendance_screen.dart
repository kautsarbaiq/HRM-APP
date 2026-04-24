import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_indicator.dart';

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

  void _startScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() { _isScanning = false; _isCheckedIn = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Check-in successful!', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Smart Check-in', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Use face recognition to check in', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
        const SizedBox(height: 24),
        _cameraPreview(),
        const SizedBox(height: 20),
        _geofenceStatus(),
        const SizedBox(height: 20),
        _checkInBtn(),
        const SizedBox(height: 20),
        _todayLog(),
      ]),
    ));
  }

  Widget _cameraPreview() {
    return GlassCard(padding: const EdgeInsets.all(8), child: AspectRatio(aspectRatio: 3 / 4,
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          gradient: const RadialGradient(colors: [Color(0xFF334155), Color(0xFF475569), Color(0xFF94A3B8)], stops: [0, 0.6, 1]))),
        Center(child: Container(width: 140, height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(70), border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.3), width: 1)),
          child: Icon(Icons.face, size: 80, color: const Color(0xFF94A3B8).withOpacity(0.3)))),
        if (_isScanning) AnimatedBuilder(animation: _scanAnim, builder: (ctx, _) {
          return Positioned(top: _scanAnim.value * 300, left: 40, right: 40,
            child: Container(height: 3, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF06B6D4).withOpacity(0.8), Colors.transparent]),
              boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.4), blurRadius: 12, spreadRadius: 4)])));
        }),
        if (_isScanning) ..._corners(),
        Positioned(bottom: 16, left: 0, right: 0, child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isScanning ? const Color(0xFF06B6D4).withOpacity(0.15) : (_isCheckedIn ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(20)),
          child: Text(
            _isScanning ? 'Scanning face...' : (_isCheckedIn ? '✓ Face verified' : 'Position your face'),
            style: GoogleFonts.poppins(color: _isScanning ? const Color(0xFF06B6D4) : (_isCheckedIn ? const Color(0xFF059669) : const Color(0xFF94A3B8)), fontSize: 13, fontWeight: FontWeight.w500)),
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
    return GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        const GlowIndicator(isActive: true, label: 'In Range'),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Office Area', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('Geofencing Active', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        ]),
      ]));
  }

  Widget _checkInBtn() {
    return AnimatedBuilder(animation: _pulseAnim, builder: (ctx, child) =>
      Transform.scale(scale: _isScanning ? 1.0 : _pulseAnim.value, child: child),
      child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: _isScanning || _isCheckedIn ? null : _startScan,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
            gradient: (!_isCheckedIn && !_isScanning) ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]) : null,
            color: _isCheckedIn ? const Color(0xFF10B981) : (_isScanning ? const Color(0xFF06B6D4).withOpacity(0.3) : null)),
          child: Container(alignment: Alignment.center, height: 56,
            child: Text(_isScanning ? 'Scanning...' : (_isCheckedIn ? '✓ Checked In' : 'Check In Now'),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
        ),
      )));
  }

  Widget _todayLog() {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's Log", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      _logRow('Check In', '08:30 AM', Icons.login, const Color(0xFF10B981)),
      const SizedBox(height: 8),
      _logRow('Break Start', '12:00 PM', Icons.free_breakfast_outlined, const Color(0xFFF59E0B)),
      const SizedBox(height: 8),
      _logRow('Break End', '01:00 PM', Icons.free_breakfast, const Color(0xFF06B6D4)),
    ]));
  }

  Widget _logRow(String label, String time, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20), const SizedBox(width: 12),
      Text(label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
      const Spacer(),
      Text(time, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}
