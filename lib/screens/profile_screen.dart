import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/role_switcher.dart';
import '../widgets/theme_toggle_widget.dart';
import '../services/mock_data_service.dart';
import '../services/role_provider.dart';
import '../services/biometric_service.dart';
import 'staff/face_enroll_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _faceEnrolled = false;
  String _enrollDate = '';

  @override
  void initState() {
    super.initState();
    _checkFaceStatus();
  }

  Future<void> _checkFaceStatus() async {
    final enrolled = await BiometricService.isFaceEnrolled();
    final timestamp = await BiometricService.getEnrollmentTimestamp();
    if (mounted) {
      setState(() {
        _faceEnrolled = enrolled;
        if (timestamp != null) {
          final dt = DateTime.tryParse(timestamp);
          if (dt != null) {
            _enrollDate = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          }
        }
      });
    }
  }

  void _openEnrollment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FaceEnrollScreen()),
    );
    if (result == true) _checkFaceStatus();
  }

  void _deleteFaceData() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Face Data?', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
        content: Text('This will remove your enrolled face. You will need to re-register before using attendance.', style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true) {
      await BiometricService.deleteFaceData();
      _checkFaceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Face data deleted', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = MockDataService.currentEmployee;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(width: 90, height: 90,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: isDark 
                ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)])
                : const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF06B6D4)]),
            boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))]),
          child: Center(child: Text(emp.name.split(' ').map((n) => n[0]).take(2).join(),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 16),
        Text(emp.name, style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w700)),
        Text(emp.position, style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 24),

        // Face Registration Status Card
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _faceEnrolled ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
              ),
              child: Icon(
                _faceEnrolled ? Icons.face_retouching_natural : Icons.face,
                color: _faceEnrolled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Face Recognition', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w600)),
              Text(
                _faceEnrolled ? 'Registered • $_enrollDate' : 'Not Registered',
                style: GoogleFonts.poppins(
                  color: _faceEnrolled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  fontSize: 12, fontWeight: FontWeight.w500,
                ),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _faceEnrolled ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _faceEnrolled ? 'Active' : 'Setup',
                style: GoogleFonts.poppins(
                  color: _faceEnrolled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  fontSize: 11, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            if (!_faceEnrolled)
              Expanded(child: SizedBox(height: 40, child: ElevatedButton.icon(
                onPressed: _openEnrollment,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text('Register Face', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                ),
              ))),
            if (_faceEnrolled) ...[
              Expanded(child: SizedBox(height: 40, child: OutlinedButton.icon(
                onPressed: _openEnrollment,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('Re-register', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF06B6D4),
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ))),
              const SizedBox(width: 10),
              SizedBox(height: 40, child: OutlinedButton(
                onPressed: _deleteFaceData,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.delete_outline, size: 18),
              )),
            ],
          ]),
        ])),
        const SizedBox(height: 16),

        // Role switcher
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Demo Mode', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
          const SizedBox(height: 4),
          Text('Settings & Roles', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Center(child: ThemeToggleWidget()),
          const SizedBox(height: 16),
          const Center(child: RoleSwitcher()),
          const SizedBox(height: 8),
          Consumer<RoleProvider>(builder: (ctx, rp, _) => Center(child: Text(
            rp.isAdmin ? 'Viewing as Admin' : 'Viewing as Staff',
            style: GoogleFonts.poppins(color: const Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.w500)))),
        ])),
        const SizedBox(height: 16),
        // Info card
        GlassCard(child: Column(children: [
          _infoRow(context, Icons.badge_outlined, 'Employee ID', emp.employeeId),
          _div(),
          _infoRow(context, Icons.email_outlined, 'Email', emp.email),
          _div(),
          _infoRow(context, Icons.business, 'Division', emp.division),
          _div(),
          _infoRow(context, Icons.work_outline, 'Position', emp.position),
          _div(),
          _infoRow(context, Icons.attach_money, 'Monthly Salary', 'RM ${emp.monthlySalary.toStringAsFixed(0)}'),
        ])),
        const SizedBox(height: 16),
        GlassCard(child: Column(children: [
          _settingsRow(context, Icons.notifications_outlined, 'Notifications'),
          _div(),
          _settingsRow(context, Icons.lock_outline, 'Privacy & Security'),
          _div(),
          _settingsRow(context, Icons.help_outline, 'Help & Support'),
          _div(),
          _settingsRow(context, Icons.info_outline, 'About'),
        ])),
        const SizedBox(height: 16),
        GlassCard(onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20), const SizedBox(width: 8),
            Text('Log Out', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w600)),
          ])),
        const SizedBox(height: 30),
      ]),
    ));
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Icon(icon, color: const Color(0xFF06B6D4), size: 20), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        Text(value, style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500)),
      ])),
    ]));
  }

  Widget _settingsRow(BuildContext context, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(onTap: () {}, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
      Icon(icon, color: const Color(0xFF94A3B8), size: 22), const SizedBox(width: 14),
      Expanded(child: Text(label, style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500))),
      const Icon(Icons.arrow_forward_ios, color: Color(0xFF475569), size: 16),
    ])));
  }

  Widget _div() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Divider(color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0), height: 1);
    });
  }
}
