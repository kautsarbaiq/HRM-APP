import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  String _selectedType = 'Annual Leave';
  XFile? _pickedImage;
  final _reasonCtrl = TextEditingController();
  final _types = [
    'Annual Leave',
    'Medical Leave*',
    'Maternity/ Paternity*',
    'Compassionate*',
    'Marriage Leave*',
    'Study/ Exam Leave*',
    'Unpaid Leave',
    'Emergency / Reason:'
  ];
  final _picker = ImagePicker();

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
        const SizedBox(height: 24),
        _applyButton(context),
        const SizedBox(height: 32),
        Text('Request History', style: GoogleFonts.poppins(color: onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        AnimationLimiter(child: Column(children: List.generate(myLeaves.length, (i) =>
          AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 400),
            child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: _leaveCard(myLeaves[i]))))))),
      ]),
    ));
  }

  Widget _applyButton(BuildContext ctx) {
    return SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
      onPressed: () => _showNewRequestSheet(ctx),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      child: Ink(decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), 
          gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
          boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Container(alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('Apply for New Leave', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]))),
    ));
  }

  void _showNewRequestSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
        final outlineColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final fieldBg = isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.8);

        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('New Request', style: GoogleFonts.poppins(color: onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: _selectedType, isExpanded: true, dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: GoogleFonts.poppins(color: onSurface, fontSize: 14),
                  icon: Icon(Icons.keyboard_arrow_down, color: onSurfaceVariant),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: onSurface)))).toList(),
                  onChanged: (v) => setModalState(() => _selectedType = v!),
                ))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(data: isDark ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF06B6D4), surface: Color(0xFF0F172A))) : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF06B6D4), surface: Colors.white)), child: child!));
                  if (picked != null) setModalState(() => _selectedRange = picked);
                },
                child: Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
                  child: Row(children: [
                    Icon(Icons.date_range, color: const Color(0xFF06B6D4), size: 20), const SizedBox(width: 12),
                    Text(_selectedRange != null ? '${DateFormat('dd MMM').format(_selectedRange!.start)} — ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)}' : 'Select date range',
                      style: GoogleFonts.poppins(color: _selectedRange != null ? onSurface : onSurfaceVariant, fontSize: 14)),
                  ])),
              ),
              const SizedBox(height: 12),
              if (_selectedType == 'Emergency / Reason:') ...[
                Container(decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
                  child: TextField(controller: _reasonCtrl, maxLines: 3, style: GoogleFonts.poppins(color: onSurface, fontSize: 14),
                    decoration: InputDecoration(hintText: 'Emergency reason details...', hintStyle: GoogleFonts.poppins(color: onSurfaceVariant), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)))),
                const SizedBox(height: 12),
              ],
              // Supporting Picture Input
              GestureDetector(
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) setModalState(() => _pickedImage = image);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: outlineColor),
                  ),
                  child: _pickedImage == null 
                    ? Column(children: [
                        Icon(Icons.add_photo_alternate_outlined, color: const Color(0xFF06B6D4), size: 28),
                        const SizedBox(height: 4),
                        Text('Add Supporting Picture', style: GoogleFonts.poppins(color: onSurface, fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('(Optional: MC, Flight Ticket, etc.)', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 10)),
                      ])
                    : Row(children: [
                        const SizedBox(width: 16),
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_pickedImage!.path, width: 44, height: 44, fit: BoxFit.cover, 
                          errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.image, size: 20)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Image Selected', style: GoogleFonts.poppins(color: onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(_pickedImage!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 11)),
                        ])),
                        IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 20), onPressed: () => setModalState(() => _pickedImage = null)),
                        const SizedBox(width: 8),
                      ]),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: () { 
                  Navigator.pop(context);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Leave request submitted!', style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: const Color(0xFF06B6D4), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); 
                  setState(() { _pickedImage = null; _reasonCtrl.clear(); _selectedRange = null; });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: Ink(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF06B6D4), boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: Container(alignment: Alignment.center, child: Text('Submit Request', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
              )),
              const SizedBox(height: 40),
            ])),
          ]),
        );
      }),
    );
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
