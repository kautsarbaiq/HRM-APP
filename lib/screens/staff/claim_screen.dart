import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../services/mock_data_service.dart';
import '../../services/ocr_service.dart';
import 'ocr_scanner_screen.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});
  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _scanComplete = false;
  ReceiptData? _ocrData;
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  final _targetCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'Travel';
  final _categories = ['Travel', 'Meals', 'Equipment', 'Medical', 'Other'];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { 
    _scanCtrl.dispose(); 
    _targetCtrl.dispose();
    _reasonCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose(); 
  }

  void _startScan() async {
    final result = await Navigator.push<ReceiptData>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OcrScannerScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    if (result != null && mounted) {
      setState(() { _scanComplete = true; _ocrData = result; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    final myClaims = MockDataService.claimRequests.where((c) => c.employeeId == '1').toList();
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Claims & Reimbursement', style: GoogleFonts.poppins(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Upload receipts and track claims', style: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 14)),
        const SizedBox(height: 24),
        _scannerArea(),
        const SizedBox(height: 16),
        _manualInputBtn(context),
        const SizedBox(height: 20),
        if (_scanComplete) _ocrResult(),
        if (_scanComplete) const SizedBox(height: 20),
        Text('Claim History', style: GoogleFonts.poppins(color: onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        AnimationLimiter(child: Column(children: List.generate(myClaims.length, (i) =>
          AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 400),
            child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: _claimCard(myClaims[i]))))))),
      ]),
    ));
  }

  Widget _scannerArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(padding: const EdgeInsets.all(8), child: AspectRatio(aspectRatio: 4 / 1.5,
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          gradient: RadialGradient(
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
            stops: const [0, 0.6, 1]))),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_isScanning ? Icons.document_scanner : Icons.receipt_long, size: 40, color: (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(_isScanning ? 0.4 : 0.2)),
          const SizedBox(height: 8),
          Text(_isScanning ? 'Scanning receipt...' : 'Tap to scan receipt', style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
        ])),
        if (_isScanning) AnimatedBuilder(animation: _scanAnim, builder: (ctx, _) =>
          Positioned(top: _scanAnim.value * 100, left: 20, right: 20,
            child: Container(height: 2, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFFF59E0B).withOpacity(0.8), Colors.transparent]),
              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 10, spreadRadius: 2)])))),
        if (!_isScanning && !_scanComplete) Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: _startScan))),
      ]))));
  }

  Widget _manualInputBtn(BuildContext ctx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SizedBox(width: double.infinity, height: 50, child: OutlinedButton(
      onPressed: () => _showManualInputSheet(ctx),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.edit_note, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
        const SizedBox(width: 8),
        Text('Input Manually', style: GoogleFonts.poppins(color: onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  void _showManualInputSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
        final outlineColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final fieldBg = isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.8);

        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurfaceVar.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Manual Claim Input', style: GoogleFonts.poppins(color: onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _inputField('Purpose / Merchant', _targetCtrl, Icons.store, isDark, fieldBg, outlineColor),
              const SizedBox(height: 12),
              _inputField('Reason', _reasonCtrl, Icons.description, isDark, fieldBg, outlineColor, maxLines: 2),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: _selectedCategory, isExpanded: true, dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: GoogleFonts.poppins(color: onSurface, fontSize: 14),
                  icon: Icon(Icons.keyboard_arrow_down, color: onSurfaceVar),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: onSurface)))).toList(),
                  onChanged: (v) => setModalState(() => _selectedCategory = v!),
                ))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 90)), lastDate: DateTime.now());
                  if (picked != null) setModalState(() => _selectedDate = picked);
                },
                child: Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
                  child: Row(children: [
                    Icon(Icons.calendar_today, color: const Color(0xFFF59E0B), size: 20), const SizedBox(width: 12),
                    Text(_selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : 'Select transaction date',
                      style: GoogleFonts.poppins(color: _selectedDate != null ? onSurface : onSurfaceVar, fontSize: 14)),
                  ])),
              ),
              const SizedBox(height: 12),
              _inputField('Amount (RM)', _amountCtrl, Icons.payments, isDark, fieldBg, outlineColor, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Claim submitted manually!', style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: Ink(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF10B981), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: Container(alignment: Alignment.center, child: Text('Submit Claim', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
              )),
              const SizedBox(height: 40),
            ])),
          ]),
        );
      }),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, bool isDark, Color bg, Color outline, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outline)),
      child: TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboardType, style: GoogleFonts.poppins(color: onSurface, fontSize: 14),
        decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFF06B6D4), size: 20), hintText: label, hintStyle: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))));
  }

  Widget _ocrResult() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withOpacity(0.1)),
          child: const Icon(Icons.check, color: Color(0xFF10B981), size: 20)),
        const SizedBox(width: 12),
        Text('Scan Result', style: GoogleFonts.poppins(color: const Color(0xFF059669), fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      _ocrRow('Date', _ocrData?.date ?? '2026-04-20', isDark), _ocrRow('Amount', 'RM ${_ocrData?.amount.toStringAsFixed(2) ?? '245.50'}', isDark), _ocrRow('Merchant', _ocrData?.merchant ?? 'Grab Malaysia', isDark), _ocrRow('Category', _ocrData?.category ?? 'Travel', isDark),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim submitted!', style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
          setState(() => _scanComplete = false);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        child: Ink(decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), 
            gradient: isDark ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]) : null,
            color: isDark ? null : const Color(0xFF0F172A),
          ),
          child: Container(alignment: Alignment.center, child: Text('Submit Claim', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)))),
      )),
    ]));
  }

  Widget _ocrRow(String l, String v, bool isDark) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
    Text(v, style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
  ]));

  Widget _claimCard(claim) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    IconData ci; Color cc;
    switch (claim.category) {
      case 'Travel': ci = Icons.flight; cc = const Color(0xFF06B6D4); break;
      case 'Meals': ci = Icons.restaurant; cc = const Color(0xFFF59E0B); break;
      case 'Equipment': ci = Icons.computer; cc = const Color(0xFF8B5CF6); break;
      case 'Medical': ci = Icons.local_hospital; cc = const Color(0xFFEF4444); break;
      default: ci = Icons.receipt; cc = const Color(0xFF94A3B8);
    }
    return GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, color: cc.withOpacity(0.1)),
        child: Icon(ci, color: cc, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(claim.description, style: GoogleFonts.poppins(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${claim.category} · ${DateFormat('dd MMM yyyy').format(claim.receiptDate)}', style: GoogleFonts.poppins(color: onSurfaceVar, fontSize: 12)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('RM ${claim.amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4), StatusBadge(status: claim.status),
      ]),
    ]));
  }
}
