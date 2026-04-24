  import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case 'Approved': return const Color(0xFF10B981).withOpacity(0.12);
      case 'Rejected': return const Color(0xFFEF4444).withOpacity(0.12);
      case 'Pending': return const Color(0xFFF59E0B).withOpacity(0.12);
      default: return const Color(0xFF94A3B8).withOpacity(0.12);
    }
  }

  Color get _fg {
    switch (status) {
      case 'Approved': return const Color(0xFF059669);
      case 'Rejected': return const Color(0xFFDC2626);
      case 'Pending': return const Color(0xFFD97706);
      default: return const Color(0xFF94A3B8);
    }
  }

  IconData get _icon {
    switch (status) {
      case 'Approved': return Icons.check_circle_outline;
      case 'Rejected': return Icons.cancel_outlined;
      case 'Pending': return Icons.access_time_rounded;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _fg.withOpacity(0.2), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, color: _fg, size: 14),
        const SizedBox(width: 4),
        Text(status, style: GoogleFonts.poppins(color: _fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
