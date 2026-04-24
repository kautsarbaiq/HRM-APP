import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';

class StaffAnalytics extends StatelessWidget {
  const StaffAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final emp = MockDataService.currentEmployee;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: AnimationLimiter(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (w) => SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: w)),
          children: [
            const SizedBox(height: 8),
            Text('My Analytics', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('Your personal performance overview', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
            const SizedBox(height: 24),
            _statsRow(),
            const SizedBox(height: 20),
            _performanceGauge(emp.performanceScore),
            const SizedBox(height: 20),
            _weeklyHoursChart(),
            const SizedBox(height: 20),
            _attendanceTrend(),
            const SizedBox(height: 20),
            _claimsBreakdown(),
            const SizedBox(height: 20),
          ],
        ),
      )),
    ));
  }

  Widget _statsRow() {
    return Row(children: [
      Expanded(child: _miniStat('Attendance', '${MockDataService.personalAttendanceRate}%', const Color(0xFF06B6D4), Icons.event_available)),
      const SizedBox(width: 10),
      Expanded(child: _miniStat('Avg Hours', '${MockDataService.personalAvgHours}h', const Color(0xFF8B5CF6), Icons.timer_outlined)),
      const SizedBox(width: 10),
      Expanded(child: _miniStat('Leave Left', '12', const Color(0xFF10B981), Icons.calendar_today_outlined)),
    ]);
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return GlassCard(padding: const EdgeInsets.all(14), child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
    ]));
  }

  Widget _performanceGauge(double score) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Performance Score', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Center(child: SizedBox(width: 140, height: 140, child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 140, height: 140, child: CircularProgressIndicator(
          value: score / 100, strokeWidth: 10, strokeCap: StrokeCap.round,
          backgroundColor: const Color(0xFF0F172A),
          valueColor: AlwaysStoppedAnimation(score > 85 ? const Color(0xFF10B981) : score > 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${score.toInt()}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
          Text('out of 100', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        ]),
      ]))),
      const SizedBox(height: 12),
      Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('⭐ Top 8% in your division', style: GoogleFonts.poppins(color: const Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600)),
      )),
    ]));
  }

  Widget _weeklyHoursChart() {
    final thisWeek = MockDataService.personalWeeklyHours;
    final lastWeek = MockDataService.personalLastWeekHours;
    final days = thisWeek.keys.toList();
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Weekly Hours', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Row(children: [
          _legendDot(const Color(0xFF06B6D4), 'This week'),
          const SizedBox(width: 12),
          _legendDot(const Color(0xFF334155), 'Last week'),
        ]),
      ]),
      const SizedBox(height: 20),
      SizedBox(height: 200, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 12,
        gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF0F172A), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
            getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) => Text(days[v.toInt()], style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(days.length, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: lastWeek[days[i]]!, width: 12, color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
          BarChartRodData(toY: thisWeek[days[i]]!, width: 12,
            gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(6)),
        ])),
      ))),
    ]));
  }

  Widget _attendanceTrend() {
    final data = MockDataService.monthlyPerformance;
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('12-Month Performance Trend', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      SizedBox(height: 180, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF0F172A), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
            getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2,
            getTitlesWidget: (v, _) {
              const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              return v.toInt() < months.length ? Text(months[v.toInt()], style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10)) : const SizedBox();
            })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 60, maxY: 100,
        lineBarsData: [LineChartBarData(
          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
          isCurved: true, curveSmoothness: 0.3,
          gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
          barWidth: 3, dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF06B6D4).withOpacity(0.15), const Color(0xFF06B6D4).withOpacity(0.0)])),
        )],
      ))),
    ]));
  }

  Widget _claimsBreakdown() {
    final claims = MockDataService.personalClaimBreakdown;
    final total = claims.values.fold(0.0, (a, b) => a + b);
    final colors = [const Color(0xFF06B6D4), const Color(0xFFF59E0B), const Color(0xFF8B5CF6), const Color(0xFFEF4444)];
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Claims Breakdown', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Row(children: [
        SizedBox(width: 120, height: 120, child: PieChart(PieChartData(
          sectionsSpace: 2, centerSpaceRadius: 28,
          sections: List.generate(claims.length, (i) {
            final entry = claims.entries.toList()[i];
            return PieChartSectionData(value: entry.value == 0 ? 0.1 : entry.value, color: colors[i], radius: 24, showTitle: false);
          }),
        ))),
        const SizedBox(width: 20),
        Expanded(child: Column(children: List.generate(claims.length, (i) {
          final entry = claims.entries.toList()[i];
          return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i])),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.key, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12))),
            Text('RM ${entry.value.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]));
        }))),
      ]),
      const SizedBox(height: 8),
      Divider(color: const Color(0xFF334155)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Total Claims', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
        Text('RM ${total.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    ]));
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11)),
    ]);
  }
}
