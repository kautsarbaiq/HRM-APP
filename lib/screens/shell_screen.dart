import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/role_provider.dart';
import '../widgets/mesh_gradient_bg.dart';
import 'staff/staff_home.dart';
import 'staff/attendance_screen.dart';
import 'staff/leave_screen.dart';
import 'staff/claim_screen.dart';
import 'staff/staff_analytics.dart';
import 'admin/admin_home.dart';
import 'admin/approval_center.dart';
import 'admin/live_tracking.dart';
import 'admin/reports_screen.dart';
import 'admin/leaderboard_screen.dart';
import 'admin/payout_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;
  int _prevRole = -1; // track role changes to reset index

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(builder: (context, rp, _) {
      // Reset to home when role changes
      final roleId = rp.isAdmin ? 1 : 0;
      if (_prevRole != -1 && _prevRole != roleId) {
        _currentIndex = 0;
      }
      _prevRole = roleId;

      final screens = rp.isAdmin
          ? <Widget>[const AdminHome(), const ApprovalCenter(), const LiveTracking(), const ReportsScreen(), const _AdminMoreScreen()]
          : <Widget>[StaffHome(onNavigate: _navigateTo), const AttendanceScreen(), const LeaveScreen(), const ClaimScreen(), const StaffAnalytics()];

      final safeIndex = _currentIndex.clamp(0, screens.length - 1);

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        extendBody: true,
        body: MeshGradientBg(child: IndexedStack(index: safeIndex, children: screens)),
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 0.5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: rp.isAdmin ? _adminNav(safeIndex) : _staffNav(safeIndex),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _staffNav(int idx) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', idx),
      _navItem(1, Icons.fingerprint_outlined, Icons.fingerprint, 'Attend', idx),
      _navItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'Leave', idx),
      _navItem(3, Icons.receipt_long_outlined, Icons.receipt_long, 'Claims', idx),
      _navItem(4, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analytics', idx),
    ]);
  }

  Widget _adminNav(int idx) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', idx),
      _navItem(1, Icons.fact_check_outlined, Icons.fact_check, 'Approvals', idx),
      _navItem(2, Icons.map_outlined, Icons.map, 'Map', idx),
      _navItem(3, Icons.analytics_outlined, Icons.analytics, 'Reports', idx),
      _navItem(4, Icons.more_horiz_outlined, Icons.more_horiz, 'More', idx),
    ]);
  }

  Widget _navItem(int i, IconData icon, IconData activeIcon, String label, int current) {
    final isActive = i == current;
    return GestureDetector(
      onTap: () => _navigateTo(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? const Color(0xFF06B6D4).withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon, color: isActive ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(
            color: isActive ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
            fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}

// Admin "More" screen with links to Leaderboard, Payout, Profile
class _AdminMoreScreen extends StatelessWidget {
  const _AdminMoreScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('More', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Additional admin features', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
        const SizedBox(height: 24),
        _moreItem(context, Icons.leaderboard, 'Leaderboard', 'Top performers ranking', const Color(0xFFF59E0B), const LeaderboardScreen()),
        _moreItem(context, Icons.payment, 'Payout Portal', 'DuitNow Malaysia transfers', const Color(0xFFE11D48), const PayoutScreen()),
        _moreItem(context, Icons.person_outline, 'Profile', 'Account & role settings', const Color(0xFF8B5CF6), const ProfileScreen()),
      ]),
    ));
  }

  Widget _moreItem(BuildContext ctx, IconData icon, String title, String sub, Color color, Widget screen) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.transparent, elevation: 0,
              leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(ctx).colorScheme.onSurface, size: 20), onPressed: () => Navigator.pop(ctx)),
              title: Text(title, style: GoogleFonts.poppins(color: Theme.of(ctx).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            body: MeshGradientBg(child: screen),
          ))),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.3) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
                child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.poppins(color: Theme.of(ctx).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(sub, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF475569), size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}
