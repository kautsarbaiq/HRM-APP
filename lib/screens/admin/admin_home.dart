import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: AnimationLimiter(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (w) => SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: w)),
          children: [
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Admin Panel', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
                Text('Dashboard', style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ])),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF06B6D4).withOpacity(0.1)),
                child: const Icon(Icons.admin_panel_settings, color: Color(0xFF06B6D4), size: 28)),
            ]),
            const SizedBox(height: 24),
            _statsRow(),
            const SizedBox(height: 20),
            _attendanceOverview(),
            const SizedBox(height: 20),
            _pendingActions(),
            const SizedBox(height: 20),
            _teamStatus(),
            const SizedBox(height: 20),
          ],
        ),
      )),
    ));
  }

  Widget _statsRow() {
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard('Attendance', '${MockDataService.attendancePercentage}%', Icons.people_alt_outlined, const Color(0xFF06B6D4), '+2.5% vs yesterday')),
        const SizedBox(width: 12),
        Expanded(child: _statCard('On Leave', '${MockDataService.onLeaveSummary}', Icons.event_busy, const Color(0xFF8B5CF6), 'employees today')),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('Pending\nClaims', '${MockDataService.totalPendingClaims}', Icons.receipt_long_outlined, const Color(0xFFF59E0B), 'awaiting review')),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Pending\nLeaves', '${MockDataService.totalPendingLeaves}', Icons.calendar_today_outlined, const Color(0xFFEF4444), 'need approval')),
      ]),
    ]);
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String sub) {
    return GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
          child: Icon(icon, color: color, size: 20)),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      Text(sub, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
    ]));
  }

  Widget _attendanceOverview() {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Attendance Overview', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _bar('Mon', 0.85, const Color(0xFF06B6D4)), _bar('Tue', 0.92, const Color(0xFF06B6D4)),
        _bar('Wed', 0.78, const Color(0xFFF59E0B)), _bar('Thu', 0.95, const Color(0xFF10B981)),
        _bar('Fri', 0.88, const Color(0xFF06B6D4)),
      ]),
    ]));
  }

  Widget _bar(String label, double fill, Color color) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text('${(fill * 100).toInt()}%', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
      const SizedBox(height: 4),
      Container(width: 36, height: 100 * fill, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [color.withOpacity(0.2), color]))),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
    ]);
  }

  Widget _pendingActions() {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Pending Actions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('${MockDataService.totalPendingClaims + MockDataService.totalPendingLeaves} items', style: GoogleFonts.poppins(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      _actionRow(Icons.calendar_today, const Color(0xFF8B5CF6), '${MockDataService.totalPendingLeaves} leave requests', 'Awaiting approval'),
      const SizedBox(height: 8),
      _actionRow(Icons.receipt_long, const Color(0xFFF59E0B), '${MockDataService.totalPendingClaims} claim requests', 'Total: RM 1,272.30'),
    ]));
  }

  Widget _actionRow(IconData icon, Color color, String title, String sub) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(sub, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
      ])),
      const Icon(Icons.arrow_forward_ios, color: Color(0xFF475569), size: 16),
    ]);
  }

  Widget _teamStatus() {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Team Status', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      _teamRow('IT', 3, 3, const Color(0xFF06B6D4)),
      _teamRow('Finance', 3, 3, const Color(0xFFF59E0B)),
      _teamRow('HR', 3, 2, const Color(0xFF8B5CF6)),
      _teamRow('Production', 3, 3, const Color(0xFF10B981)),
    ]));
  }

  Widget _teamRow(String dept, int total, int present, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Container(width: 4, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(dept, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        Text('$present / $total present', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
      ])),
      SizedBox(width: 60, child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: present / total, backgroundColor: const Color(0xFF0F172A), valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
    ]));
  }
}
