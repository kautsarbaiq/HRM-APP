import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';
import '../../models/employee.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Employee? _selectedEmp;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _selectedEmp = MockDataService.allEmployees.first;
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    final gridColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    
    return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Advanced Reports', style: GoogleFonts.poppins(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Detailed employee analytics', style: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 14)),
        const SizedBox(height: 16),
        // Employee selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(child: DropdownButton<Employee>(
            value: _selectedEmp, isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: GoogleFonts.poppins(color: onSurface, fontSize: 14),
            icon: Icon(Icons.keyboard_arrow_down, color: onSurfaceVar),
            items: MockDataService.allEmployees.map((e) => DropdownMenuItem(value: e,
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF06B6D4).withOpacity(0.1)),
                  child: Center(child: Text(e.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: const Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 10),
                Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: onSurface, fontSize: 14))),
                Text(e.division, style: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 11)),
              ]),
            )).toList(),
            onChanged: (v) => setState(() => _selectedEmp = v),
          )),
        ),
        const SizedBox(height: 16),
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isDark ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]) : null,
              color: isDark ? null : const Color(0xFF0F172A),
            ),
            indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 12),
            labelColor: Colors.white, unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            tabs: const [Tab(text: 'Daily'), Tab(text: 'Weekly'), Tab(text: '12 Mon'), Tab(text: 'Yearly')],
          ),
        ),
      ])),
      const SizedBox(height: 16),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _dailyView(), _weeklyView(), _monthlyView(), _yearlyView(),
      ])),
    ]));
  }

  Color get _gridColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get _axisColor => Theme.of(context).colorScheme.onSurfaceVariant;

  Widget _dailyView() {
    final data = MockDataService.dailyAttendancePercent.take(7).toList();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return _chartPage(
      'Daily Attendance', 'This Week',
      SizedBox(height: 220, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 100,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: _gridColor, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => v.toInt() < days.length ? Text(days[v.toInt()], style: GoogleFonts.poppins(color: _axisColor, fontSize: 11)) : const SizedBox())),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(data.length, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: data[i], width: 20, borderRadius: BorderRadius.circular(8),
            gradient: data[i] > 0 ? const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]) : null,
            color: data[i] == 0 ? const Color(0xFF334155) : null),
        ])),
      ))),
      [_statCard('Avg Attendance', '${data.where((d) => d > 0).fold(0.0, (a, b) => a + b) ~/ data.where((d) => d > 0).length}%', const Color(0xFF06B6D4)),
       _statCard('Days Present', '${data.where((d) => d > 0).length}/7', const Color(0xFF10B981)),
       _statCard('On Time Rate', '85%', const Color(0xFF8B5CF6))],
    );
  }

  Widget _weeklyView() {
    final data = MockDataService.weeklyHours;
    return _chartPage(
      'Weekly Working Hours', 'Last 12 Weeks',
      SizedBox(height: 220, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: _gridColor, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (v, _) => Text('W${v.toInt() + 1}', style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 30, maxY: 50,
        lineBarsData: [LineChartBarData(
          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
          isCurved: true, gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
          barWidth: 3, dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: const Color(0xFF06B6D4), strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF10B981).withOpacity(0.12), Colors.transparent])),
        )],
      ))),
      [_statCard('Avg Hours', '41.3h', const Color(0xFF06B6D4)), _statCard('Max Week', '46h', const Color(0xFF10B981)), _statCard('Min Week', '37h', const Color(0xFFF59E0B))],
    );
  }

  Widget _monthlyView() {
    final data = MockDataService.monthlyPerformance;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return _chartPage(
      'Monthly Performance', '12-Month Trend',
      SizedBox(height: 220, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: _gridColor, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (v, _) => v.toInt() < months.length ? Text(months[v.toInt()], style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)) : const SizedBox())),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 60, maxY: 100,
        lineBarsData: [LineChartBarData(
          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
          isCurved: true, gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)]),
          barWidth: 3, dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF8B5CF6).withOpacity(0.12), Colors.transparent])),
        )],
      ))),
      [_statCard('Avg Score', '88.5', const Color(0xFF8B5CF6)), _statCard('Best Month', 'Dec: 92', const Color(0xFF10B981)), _statCard('Growth', '+18%', const Color(0xFF06B6D4))],
    );
  }

  Widget _yearlyView() {
    return _chartPage(
      'Yearly Summary', '2025 vs 2026',
      SizedBox(height: 220, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 100,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: _gridColor, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Attendance', 'Perf.', 'Claims', 'On-time'];
            return v.toInt() < labels.length ? Text(labels[v.toInt()], style: GoogleFonts.poppins(color: _axisColor, fontSize: 10)) : const SizedBox();
          })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          _yearGroup(0, 82, 88), _yearGroup(1, 75, 85), _yearGroup(2, 90, 95), _yearGroup(3, 80, 87),
        ],
      ))),
      [_statCard('Overall 2026', '88.7', const Color(0xFF06B6D4)), _statCard('vs 2025', '+7.2%', const Color(0xFF10B981)), _statCard('Rank', '#3/48', const Color(0xFF8B5CF6))],
    );
  }

  BarChartGroupData _yearGroup(int x, double v1, double v2) => BarChartGroupData(x: x, barRods: [
    BarChartRodData(toY: v1, width: 14, color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
    BarChartRodData(toY: v2, width: 14, gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(6)),
  ]);

  Widget _chartPage(String title, String subtitle, Widget chart, List<Widget> stats) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        Text(subtitle, style: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 12)),
        const SizedBox(height: 20), chart,
      ])),
      const SizedBox(height: 12),
      Row(children: stats.map((s) => Expanded(child: s)).toList()),
      const SizedBox(height: 20),
    ]));
  }

  Widget _statCard(String label, String value, Color color) {
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GlassCard(padding: const EdgeInsets.all(12), child: Column(children: [
        Text(value, style: GoogleFonts.poppins(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 10)),
      ])),
    );
  }
}
