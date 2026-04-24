import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});
  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> with TickerProviderStateMixin {
  String _selectedMethod = 'DuitNow';
  String _selectedDiv = 'IT';
  bool _showSuccess = false;
  bool _isBatchMode = false;
  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  final _methods = [
    {'name': 'DuitNow', 'icon': Icons.swap_horiz, 'color': const Color(0xFFE11D48)},
    {'name': 'Maybank', 'icon': Icons.account_balance, 'color': const Color(0xFFFBBF24)},
    {'name': 'CIMB', 'icon': Icons.account_balance_wallet, 'color': const Color(0xFFDC2626)},
    {'name': 'TNG', 'icon': Icons.phone_android, 'color': const Color(0xFF2563EB)},
    {'name': 'GrabPay', 'icon': Icons.electric_bolt, 'color': const Color(0xFF16A34A)},
  ];

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() { _successCtrl.dispose(); super.dispose(); }

  void _processPayment() {
    setState(() => _showSuccess = true);
    _successCtrl.forward(from: 0);
  }

  void _dismissSuccess() {
    _successCtrl.reverse().then((_) {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Stack(children: [
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          // DuitNow header
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE11D48).withOpacity(0.1)),
              child: const Icon(Icons.swap_horiz, color: Color(0xFFE11D48), size: 28)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payout Portal', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              Row(children: [
                Text('🇲🇾 ', style: GoogleFonts.poppins(fontSize: 14)),
                Text('DuitNow Malaysia', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
              ]),
            ]),
          ]),
          const SizedBox(height: 24),
          // Payment method selector
          Text('Payment Method', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(height: 90, child: ListView.builder(
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
            itemCount: _methods.length,
            itemBuilder: (ctx, i) {
              final m = _methods[i];
              final selected = _selectedMethod == m['name'];
              final color = m['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = m['name'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 80, margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? color : const Color(0xFF334155), width: selected ? 2 : 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(m['icon'] as IconData, color: color, size: 28),
                    const SizedBox(height: 6),
                    Text(m['name'] as String, style: GoogleFonts.poppins(color: selected ? color : const Color(0xFF94A3B8), fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              );
            },
          )),
          const SizedBox(height: 24),
          // Mode toggle
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isBatchMode = false),
              child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: !_isBatchMode ? const Color(0xFF06B6D4).withOpacity(0.1) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: !_isBatchMode ? const Color(0xFF06B6D4) : const Color(0xFF334155))),
                child: Column(children: [
                  Icon(Icons.person, color: !_isBatchMode ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8), size: 24),
                  Text('Individual', style: GoogleFonts.poppins(color: !_isBatchMode ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isBatchMode = true),
              child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isBatchMode ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: _isBatchMode ? const Color(0xFF8B5CF6) : const Color(0xFF334155))),
                child: Column(children: [
                  Icon(Icons.groups, color: _isBatchMode ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8), size: 24),
                  Text('Batch Pay', style: GoogleFonts.poppins(color: _isBatchMode ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 20),
          // Content based on mode
          _isBatchMode ? _batchMode() : _individualMode(),
        ]),
      ),
      // Success overlay
      if (_showSuccess) _successOverlay(),
    ]));
  }

  Widget _individualMode() {
    final emp = MockDataService.allEmployees.first;
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Transfer Details', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      // Employee picker
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF06B6D4).withOpacity(0.1)),
            child: Center(child: Text('AR', style: GoogleFonts.poppins(color: const Color(0xFF06B6D4), fontSize: 14, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(emp.employeeId, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
          ])),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
        ]),
      ),
      const SizedBox(height: 14),
      _detailRow('Amount', 'RM ${emp.monthlySalary.toStringAsFixed(2)}'),
      _detailRow('Method', _selectedMethod),
      _detailRow('Reference', 'SAL-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}'),
      const SizedBox(height: 20),
      _transferButton(),
    ]));
  }

  Widget _batchMode() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Division selector
      Text('Select Division', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: ['IT', 'Finance', 'HR', 'Production'].map((d) => FilterChip(
        label: Text(d, style: GoogleFonts.poppins(color: _selectedDiv == d ? Colors.white : const Color(0xFF94A3B8), fontSize: 13)),
        selected: _selectedDiv == d, onSelected: (_) => setState(() => _selectedDiv = d),
        selectedColor: const Color(0xFF8B5CF6), backgroundColor: Colors.white.withOpacity(0.15),
        side: BorderSide(color: _selectedDiv == d ? const Color(0xFF8B5CF6) : const Color(0xFF334155)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), showCheckmark: false,
      )).toList()),
      const SizedBox(height: 16),
      // Batch summary
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Batch Summary — $_selectedDiv', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        ...MockDataService.employeesByDivision(_selectedDiv).map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withOpacity(0.1)),
              child: Center(child: Text(e.name.split(' ').map((n) => n[0]).take(2).join(), style: GoogleFonts.poppins(color: const Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: Text(e.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
            Text('RM ${e.monthlySalary.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        )),
        Divider(color: const Color(0xFF334155), height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Payout', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('RM ${MockDataService.employeesByDivision(_selectedDiv).fold(0.0, (a, e) => a + e.monthlySalary).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        _transferButton(),
      ])),
    ]);
  }

  Widget _transferButton() {
    return SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
      onPressed: _processPayment,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)])),
        child: Container(alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('Transfer Now', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ])),
      ),
    ));
  }

  Widget _successOverlay() {
    final total = _isBatchMode
        ? MockDataService.employeesByDivision(_selectedDiv).fold(0.0, (a, e) => a + e.monthlySalary)
        : MockDataService.allEmployees.first.monthlySalary;
    return GestureDetector(
      onTap: _dismissSuccess,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(child: AnimatedBuilder(
          animation: _successScale,
          builder: (ctx, child) => Transform.scale(scale: _successScale.value, child: child),
          child: Container(
            width: 320, padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 16))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withOpacity(0.1)),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48)),
              const SizedBox(height: 16),
              Text('Transfer Successful!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('RM ${total.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: const Color(0xFF06B6D4), fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('via $_selectedMethod', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
              const SizedBox(height: 16),
              // Receipt preview
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
                child: Column(children: [
                  _receiptRow('Reference', 'DN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                  _receiptRow('Date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  _receiptRow('Time', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
                  _receiptRow('Status', '✅ Completed'),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _dismissSuccess, icon: const Icon(Icons.download, size: 18), label: Text('Receipt', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF06B6D4), side: const BorderSide(color: Color(0xFF06B6D4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 12)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: _dismissSuccess, child: Text('Done', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 12)),
                )),
              ]),
            ]),
          ),
        )),
      ),
    );
  }

  Widget _detailRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
    Text(v, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
  ]));

  Widget _receiptRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
    Text(v, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
  ]));
}
