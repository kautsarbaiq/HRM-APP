import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../services/mock_data_service.dart';

class ApprovalCenter extends StatefulWidget {
  const ApprovalCenter({super.key});
  @override
  State<ApprovalCenter> createState() => _ApprovalCenterState();
}

class _ApprovalCenterState extends State<ApprovalCenter> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Approval Center', style: GoogleFonts.poppins(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Review and manage requests', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 20),
        Container(decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0))),
          child: TabBar(controller: _tabCtrl,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(14), 
              gradient: isDark ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]) : null, 
              color: isDark ? null : const Color(0xFF06B6D4)
            ),
            indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 14),
            labelColor: Colors.white, unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            tabs: const [Tab(text: 'Leave Requests'), Tab(text: 'Claims')])),
      ])),
      const SizedBox(height: 16),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [_leaveTab(), _claimTab()])),
    ]));
  }

  Widget _leaveTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final pending = MockDataService.leaveRequests.where((l) => l.status == 'Pending').toList();
    return ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [AnimationLimiter(child: Column(children: List.generate(pending.length, (i) {
        final l = pending[i];
        return AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 400),
          child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: GlassCard(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.2), const Color(0xFF06B6D4).withOpacity(0.2)])),
                  child: Center(child: Text(l.employeeName.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.employeeName, style: GoogleFonts.poppins(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('${l.type} Leave · ${l.totalDays} day(s)', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 12)),
                ])),
                StatusBadge(status: l.status),
              ]),
              const SizedBox(height: 12),
              Row(children: [const Icon(Icons.date_range, color: Color(0xFF06B6D4), size: 16), const SizedBox(width: 6),
                Text('${DateFormat('dd MMM').format(l.startDate)} — ${DateFormat('dd MMM yyyy').format(l.endDate)}', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 13))]),
              const SizedBox(height: 4),
              Text(l.reason, style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 12),
              // View Attachment Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text('View Attachment', style: GoogleFonts.poppins(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF06B6D4),
                  side: const BorderSide(color: Color(0xFF06B6D4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [Expanded(child: _btn('Reject', const Color(0xFFEF4444), Icons.close, () => _snack('Leave rejected', const Color(0xFFEF4444)))),
                const SizedBox(width: 10), Expanded(child: _btn('Approve', const Color(0xFF10B981), Icons.check, () => _snack('Leave approved', const Color(0xFF10B981))))]),
            ]),
          ))));
      })))],
    );
  }

  Widget _claimTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final pending = MockDataService.claimRequests.where((c) => c.status == 'Pending').toList();
    return ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [AnimationLimiter(child: Column(children: List.generate(pending.length, (i) {
        final c = pending[i];
        return AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 400),
          child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: GlassCard(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.2), const Color(0xFF06B6D4).withOpacity(0.2)])),
                  child: Center(child: Text(c.employeeName.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.employeeName, style: GoogleFonts.poppins(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('${c.category} · ${DateFormat('dd MMM yyyy').format(c.receiptDate)}', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 12)),
                ])),
                Text('RM ${c.amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Text(c.description, style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? const Color(0xFF1E293B) : Colors.white, border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                child: Row(children: [
                  Icon(Icons.receipt, color: isDark ? const Color(0xFF475569) : onSurfaceVariant, size: 24), const SizedBox(width: 8),
                  Expanded(child: Text('Receipt attached', style: GoogleFonts.poppins(color: isDark ? const Color(0xFF475569) : onSurfaceVariant, fontSize: 12))),
                  TextButton(onPressed: () {}, child: Text('View', style: GoogleFonts.poppins(color: const Color(0xFF06B6D4), fontWeight: FontWeight.w600, fontSize: 12))),
                ])),
              const SizedBox(height: 14),
              Row(children: [Expanded(child: _btn('Reject', const Color(0xFFEF4444), Icons.close, () => _snack('Claim rejected', const Color(0xFFEF4444)))),
                const SizedBox(width: 10), Expanded(child: _btn('Approve', const Color(0xFF10B981), Icons.check, () => _snack('Claim approved', const Color(0xFF10B981))))]),
            ]),
          ))));
      })))],
    );
  }

  Widget _btn(String label, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(height: 42, child: ElevatedButton.icon(
      onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: BorderSide(color: color.withOpacity(0.2)), elevation: 0)));
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
