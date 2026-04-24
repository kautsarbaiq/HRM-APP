import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/role_provider.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(builder: (context, rp, _) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _opt('Staff', rp.isStaff, Icons.person_outline, () => rp.setStaff()),
          _opt('Admin', rp.isAdmin, Icons.admin_panel_settings_outlined, () => rp.setAdmin()),
        ]),
      );
    });
  }

  Widget _opt(String label, bool selected, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]) : null,
          boxShadow: selected ? [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Row(children: [
          Icon(icon, color: selected ? Colors.white : const Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(color: selected ? Colors.white : const Color(0xFF94A3B8), fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
        ]),
      ),
    );
  }
}
