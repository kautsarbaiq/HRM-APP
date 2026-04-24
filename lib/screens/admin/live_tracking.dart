import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';

class LiveTracking extends StatefulWidget {
  const LiveTracking({super.key});
  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  String _selectedDivision = 'All';

  @override
  Widget build(BuildContext context) {
    final emps = MockDataService.employeesByDivision(_selectedDivision);
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Live Tracking', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Real-time employee locations', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
        const SizedBox(height: 16),
        // Division filter chips
        SizedBox(height: 40, child: ListView(
          scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
          children: MockDataService.divisions.map((d) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(d, style: GoogleFonts.poppins(color: _selectedDivision == d ? Colors.white : const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
              selected: _selectedDivision == d,
              onSelected: (_) => setState(() => _selectedDivision = d),
              selectedColor: const Color(0xFF06B6D4),
              backgroundColor: Colors.white.withOpacity(0.15),
              side: BorderSide(color: _selectedDivision == d ? const Color(0xFF06B6D4) : const Color(0xFF334155)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          )).toList(),
        )),
      ])),
      const SizedBox(height: 12),
      // Map area
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          padding: const EdgeInsets.all(0), margin: EdgeInsets.zero,
          child: Stack(children: [
            // Mock map
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _MapPainter(),
                child: Container(),
              ),
            ),
            // Employee markers
            ...emps.map((e) {
              final ox = ((e.longitude - 101.69) * 2500).clamp(30.0, MediaQuery.of(context).size.width - 100);
              final oy = ((3.155 - e.latitude) * 2500).clamp(30.0, 400.0);
              final color = _divColor(e.division);
              return Positioned(left: ox, top: oy, child: GestureDetector(
                onTap: () => _showEmpDetail(context, e),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]),
                    child: Center(child: Text(e.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                    child: Text(e.name.split(' ').first, style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ));
            }),
            // Count overlay
            Positioned(top: 16, right: 16, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people, color: Color(0xFF06B6D4), size: 18),
                const SizedBox(width: 6),
                Text('${emps.length} online', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            )),
          ]),
        ),
      )),
      const SizedBox(height: 12),
      // Employee list
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(height: 90, child: ListView.builder(
          scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
          itemCount: emps.length,
          itemBuilder: (ctx, i) {
            final e = emps[i]; final c = _divColor(e.division);
            return Container(
              width: 72, margin: const EdgeInsets.only(right: 10),
              child: Column(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.15), border: Border.all(color: c, width: 2)),
                  child: Center(child: Text(e.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: c, fontSize: 13, fontWeight: FontWeight.w700)))),
                const SizedBox(height: 4),
                Text(e.name.split(' ').first, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                Text(e.division, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 9)),
              ]),
            );
          },
        )),
      ),
      const SizedBox(height: 12),
    ]));
  }

  Color _divColor(String div) {
    switch (div) {
      case 'IT': return const Color(0xFF06B6D4);
      case 'Finance': return const Color(0xFFF59E0B);
      case 'HR': return const Color(0xFF8B5CF6);
      case 'Production': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  void _showEmpDetail(BuildContext ctx, emp) {
    showModalBottomSheet(context: ctx, backgroundColor: Colors.transparent, builder: (_) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: _divColor(emp.division).withOpacity(0.15)),
            child: Center(child: Text(emp.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: _divColor(emp.division), fontSize: 18, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${emp.position} · ${emp.division}', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 16),
        _detailRow('Employee ID', emp.employeeId),
        _detailRow('Email', emp.email),
        _detailRow('Performance', '${emp.performanceScore.toInt()}/100'),
        _detailRow('Status', '🟢 Online · In Geofence'),
        const SizedBox(height: 8),
      ]),
    ));
  }

  Widget _detailRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
    Flexible(child: Text(v, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
  ]));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFF0F7FF));
    final roadPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 2..style = PaintingStyle.stroke;
    // Grid roads
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(Offset(0, size.height * i / 7), Offset(size.width, size.height * i / 7), roadPaint);
      canvas.drawLine(Offset(size.width * i / 7, 0), Offset(size.width * i / 7, size.height), roadPaint);
    }
    // Main roads (thicker)
    final mainRoad = Paint()..color = const Color(0xFF475569)..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), mainRoad);
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), mainRoad);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), mainRoad);
    // Building blocks
    final blockPaint = Paint()..color = const Color(0xFFE8F4FD);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.2, size.height * 0.15), const Radius.circular(4)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.4, size.height * 0.5, size.width * 0.25, size.height * 0.2), const Radius.circular(4)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.75, size.height * 0.1, size.width * 0.2, size.height * 0.15), const Radius.circular(4)), blockPaint);
    // Office marker
    final officePaint = Paint()..color = const Color(0xFF06B6D4).withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35), 50, officePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35), 30, Paint()..color = const Color(0xFF06B6D4).withOpacity(0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
