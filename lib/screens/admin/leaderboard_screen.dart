import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedDiv = 'All';

  @override
  Widget build(BuildContext context) {
    var emps = MockDataService.employeesByDivision(_selectedDiv);
    emps.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
    return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Leaderboard', style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Top performers ranking', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
          children: MockDataService.divisions.map((d) => Padding(padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(d, style: GoogleFonts.poppins(color: _selectedDiv == d ? Colors.white : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              selected: _selectedDiv == d, onSelected: (_) => setState(() => _selectedDiv = d),
              selectedColor: const Color(0xFF06B6D4), backgroundColor: Colors.white.withOpacity(0.6),
              side: BorderSide(color: _selectedDiv == d ? const Color(0xFF06B6D4) : const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), showCheckmark: false,
            ),
          )).toList(),
        )),
      ])),
      const SizedBox(height: 16),
      // Top 3 podium
      if (emps.length >= 3) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildPodium(emps)),
      const SizedBox(height: 16),
      // Full list
      Expanded(child: AnimationLimiter(child: ListView.builder(
        physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: emps.length,
        itemBuilder: (ctx, i) {
          final e = emps[i];
          return AnimationConfiguration.staggeredList(
            position: i, duration: const Duration(milliseconds: 400),
            child: SlideAnimation(verticalOffset: 40, child: FadeInAnimation(child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                SizedBox(width: 32, child: Text(_rankEmoji(i), style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
                const SizedBox(width: 12),
                Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: _divColor(e.division).withOpacity(0.12), border: Border.all(color: _divColor(e.division), width: 1.5)),
                  child: Center(child: Text(e.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: _divColor(e.division), fontSize: 14, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.name, style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${e.position} · ${e.division}', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${e.performanceScore.toInt()}', style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('pts', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10)),
                ]),
              ]),
            ))),
          );
        },
      ))),
    ]));
  }

  Widget _buildPodium(List emps) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: _podiumCard(emps[1], 2, 100, const Color(0xFFC0C0C0))),
      const SizedBox(width: 8),
      Expanded(child: _podiumCard(emps[0], 1, 130, const Color(0xFFFFD700))),
      const SizedBox(width: 8),
      Expanded(child: _podiumCard(emps[2], 3, 80, const Color(0xFFCD7F32))),
    ]);
  }

  Widget _podiumCard(emp, int rank, double height, Color medalColor) {
    return GlassCard(padding: const EdgeInsets.all(12), child: Column(children: [
      Text(_rankEmoji(rank - 1), style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 8),
      Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: medalColor.withOpacity(0.15), border: Border.all(color: medalColor, width: 2)),
        child: Center(child: Text(emp.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: medalColor.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 8),
      Text(emp.name.split(' ').first, style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      Text('${emp.performanceScore.toInt()} pts', style: GoogleFonts.poppins(color: const Color(0xFF06B6D4), fontSize: 14, fontWeight: FontWeight.w800)),
    ]));
  }

  String _rankEmoji(int i) {
    switch (i) { case 0: return '🥇'; case 1: return '🥈'; case 2: return '🥉'; default: return '#${i + 1}'; }
  }

  Color _divColor(String div) {
    switch (div) { case 'IT': return const Color(0xFF06B6D4); case 'Finance': return const Color(0xFFF59E0B); case 'HR': return const Color(0xFF8B5CF6); case 'Production': return const Color(0xFF10B981); default: return const Color(0xFF64748B); }
  }
}
