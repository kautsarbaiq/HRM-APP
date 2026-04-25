import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../services/mock_data_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  DateTimeRange? _selectedRange;
  String _selectedType = 'Annual';
  final _reasonCtrl = TextEditingController();
  final _types = ['Annual', 'Sick', 'Personal', 'Maternity'];

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    
    final myLeaves = MockDataService.leaveRequests.where((l) => l.employeeId == '1').toList();
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Leave Application', style: GoogleFonts.poppins(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Apply for leave and track requests', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 24),
        _leaveBalance(),
        const SizedBox(height: 20),
        _form(context),
        const SizedBox(height: 24),
        Text('Request History', style: GoogleFonts.poppins(color: onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        AnimationLimiter(child: Column(children: List.generate(myLeaves.length, (i) =>
          AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 400),
            child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: _leaveCard(myLeaves[i]))))))),
      ]),
    ));
  }

  Widget _leaveBalance() {
    return Row(children: [
      Expanded(child: _balCard('Annual', '12', const Color(0xFF06B6D4))),
      const SizedBox(width: 10),
      Expanded(child: _balCard('Sick', '8', const Color(0xFFF59E0B))),
      const SizedBox(width: 10),
      Expanded(child: _balCard('Personal', '3', const Color(0xFF8B5CF6))),
    ]);
  }

  Widget _balCard(String l, String c, Color color) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassCard(padding: const EdgeInsets.all(14), child: Column(children: [
      Text(c, style: GoogleFonts.poppins(color: color, fontSize: 28, fontWeight: FontWeight.w700)),
      Text(l, style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 12)),
      Text('days left', style: GoogleFonts.poppins(color: onSurfaceVariant.withOpacity(0.8), fontSize: 10)),
    ]));
  }

  Widget _form(BuildContext ctx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('New Request', style: GoogleFonts.poppins(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _selectedType, isExpanded: true, dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))))).toList(),
          onChanged: (v) => setState(() => _selectedType = v!),
        ))),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final picked = await showDateRangePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF06B6D4), surface: Colors.white)), child: child!));
          if (picked != null) setState(() => _selectedRange = picked);
        },
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A))),
          child: Row(children: [
            Icon(Icons.date_range, color: isDark ? const Color(0xFF06B6D4) : const Color(0xFF0F172A), size: 20), const SizedBox(width: 12),
            Text(_selectedRange != null ? '${DateFormat('dd MMM').format(_selectedRange!.start)} — ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)}' : 'Select date range',
              style: GoogleFonts.poppins(color: _selectedRange != null ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? const Color(0xFF475569) : const Color(0xFF64748B)), fontSize: 14)),
          ])),
      ),
      const SizedBox(height: 12),
      Container(decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A))),
        child: TextField(controller: _reasonCtrl, maxLines: 3, style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(hintText: 'Reason for leave...', hintStyle: GoogleFonts.poppins(color: isDark ? const Color(0xFF475569) : const Color(0xFF64748B)), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: () { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Leave request submitted!', style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: const Color(0xFF06B6D4), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        child: Ink(decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), 
            gradient: isDark ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]) : null,
            color: isDark ? null : const Color(0xFF0F172A),
          ),
          child: Container(alignment: Alignment.center, child: Text('Submit Request', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)))),
      )),
    ]));
  }

  Widget _leaveCard(leave) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withOpacity(0.1)),
          child: const Icon(Icons.calendar_today, color: Color(0xFF8B5CF6), size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(leave.type, style: GoogleFonts.poppins(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
          Text('${DateFormat('dd MMM').format(leave.startDate)} — ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
            style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 12)),
        ])),
        StatusBadge(status: leave.status),
      ]),
      const SizedBox(height: 8),
      Text(leave.reason, style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 13)),
      const SizedBox(height: 4),
      Text('${leave.totalDays} day(s)', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
    ]));
  }
}
