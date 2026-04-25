import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/mesh_gradient_bg.dart';
import '../../services/mock_data_service.dart';
import '../profile_screen.dart';

class StaffHome extends StatefulWidget {
  final Function(int)? onNavigate;
  const StaffHome({super.key, this.onNavigate});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  late Timer _timer;
  String _currentTime = '';
  String _currentDate = '';
  double _earnedToday = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final emp = MockDataService.currentEmployee;
    // Calculate salary earned since 8:30 AM
    final workStart = DateTime(now.year, now.month, now.day, 8, 30);
    if (now.isAfter(workStart)) {
      final worked = now.difference(workStart).inSeconds;
      _earnedToday = (emp.hourlySalary / 3600) * worked;
    }
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(now);
        _currentDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
      });
    }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 👋';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final emp = MockDataService.currentEmployee;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: AnimationLimiter(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (w) => SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: w)),
          children: [
            const SizedBox(height: 8),
            _header(emp),
            const SizedBox(height: 24),
            _salaryCounter(),
            const SizedBox(height: 16),
            _attendanceCard(),
            const SizedBox(height: 24),
            _quickActions(),
            const SizedBox(height: 24),
            _recentActivity(),
            const SizedBox(height: 20),
          ],
        ),
      )),
    ));
  }

  Widget _header(emp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (routeCtx) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.transparent, elevation: 0,
              leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(routeCtx).colorScheme.onSurface, size: 20), onPressed: () => Navigator.pop(routeCtx)),
              title: Text('Profile', style: GoogleFonts.poppins(color: Theme.of(routeCtx).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            body: const MeshGradientBg(child: ProfileScreen()),
          ))),
          child: Row(children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
                boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))]),
              child: Center(child: Text(emp.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(), style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
              Text(emp.name, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700)),
            ])),
          ]),
        ),
      ),
      IconButton(onPressed: () {}, icon: Stack(children: [
        Icon(Icons.notifications_outlined, color: const Color(0xFF94A3B8), size: 28),
        Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEF4444), border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 1.5)))),
      ])),
    ]);
  }

  Widget _salaryCounter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Working Duration to Salary', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('LIVE', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]).createShader(b),
          child: Text('RM ${_earnedToday.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
        ),
        Text('earned today', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_earnedToday / MockDataService.currentEmployee.dailySalary).clamp(0, 1),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), minHeight: 6,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF06B6D4)),
          ),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RM 0', style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 10)),
          Text('RM ${MockDataService.currentEmployee.dailySalary.toStringAsFixed(0)}/day', style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _attendanceCard() {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Attendance Status', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('Checked In', style: GoogleFonts.poppins(color: const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      Center(child: ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]).createShader(b),
        child: Text(_currentTime, style: GoogleFonts.poppins(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: 4)),
      )),
      Center(child: Text(_currentDate, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12))),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _timeInfo('Check In', '08:30 AM', Icons.login),
        Container(width: 1, height: 28, color: const Color(0xFF334155)),
        _timeInfo('Check Out', '--:-- --', Icons.logout),
        Container(width: 1, height: 28, color: const Color(0xFF334155)),
        _timeInfo('Working', '${DateTime.now().hour - 8}h ${DateTime.now().minute}m', Icons.timer_outlined),
      ]),
    ]));
  }

  Widget _timeInfo(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFF06B6D4), size: 18),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
      Text(label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10)),
    ]);
  }

  Widget _quickActions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: [
        QuickActionCard(icon: Icons.fingerprint, label: 'Attendance', color: const Color(0xFF06B6D4), onTap: () => widget.onNavigate?.call(1)),
        const SizedBox(width: 12),
        QuickActionCard(icon: Icons.calendar_today_outlined, label: 'Leave', color: const Color(0xFF8B5CF6), onTap: () => widget.onNavigate?.call(2)),
        const SizedBox(width: 12),
        QuickActionCard(icon: Icons.receipt_long_outlined, label: 'Claims', color: const Color(0xFFF59E0B), onTap: () => widget.onNavigate?.call(3)),
        const SizedBox(width: 12),
        QuickActionCard(icon: Icons.bar_chart, label: 'Analytics', color: const Color(0xFF10B981), onTap: () => widget.onNavigate?.call(4)),
      ])),
    ]);
  }

  Widget _recentActivity() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Recent Activity', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      GlassCard(padding: const EdgeInsets.all(0), child: Column(children: [
        _activityItem(Icons.check_circle, const Color(0xFF10B981), 'Checked in today', '08:30 AM · On Time', isFirst: true),
        Divider(color: const Color(0xFF334155).withOpacity(0.5), height: 1, indent: 56),
        _activityItem(Icons.calendar_today, const Color(0xFFF59E0B), 'Leave request submitted', 'Annual Leave · 4 days · Pending'),
        Divider(color: const Color(0xFF334155).withOpacity(0.5), height: 1, indent: 56),
        _activityItem(Icons.receipt_long, const Color(0xFF8B5CF6), 'Claim approved', 'Nasi Kandar lunch · RM 87.00', isLast: true),
      ])),
    ]);
  }

  Widget _activityItem(IconData icon, Color color, String title, String sub, {bool isFirst = false, bool isLast = false}) {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: isFirst ? 16 : 12, bottom: isLast ? 16 : 12),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(sub, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        ])),
      ]),
    );
  }
}
