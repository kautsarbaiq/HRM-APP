import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ocr_service.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});
  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> with TickerProviderStateMixin {
  late AnimationController _beamCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _beamAnim;
  late Animation<double> _resultSlide;
  late Animation<double> _resultFade;

  bool _isScanning = true;
  ReceiptData? _result;
  int _revealedFields = 0;

  @override
  void initState() {
    super.initState();
    
    _beamCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _beamAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _beamCtrl, curve: Curves.easeInOut));
    
    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut));
    _resultFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut));
    
    _startScan();
  }

  void _startScan() async {
    final result = await OcrService.scanReceipt();
    if (!mounted) return;
    
    _beamCtrl.stop();
    setState(() { _isScanning = false; _result = result; });
    _resultCtrl.forward();
    
    // Reveal fields one by one
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _revealedFields = i);
    }
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Scan Receipt', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scanner viewport
          Expanded(
            flex: _isScanning ? 3 : 2,
            child: AnimatedBuilder(
              animation: _beamAnim,
              builder: (ctx, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Dark viewport
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const RadialGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            radius: 1.2,
                          ),
                        ),
                      ),
                      
                      // Receipt outline
                      Center(
                        child: Container(
                          width: 220,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isScanning
                                ? const Color(0xFFF59E0B).withOpacity(0.5)
                                : const Color(0xFF10B981).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isScanning ? Icons.receipt_long : Icons.check_circle_outline,
                                size: 48,
                                color: _isScanning
                                  ? Colors.white.withOpacity(0.1)
                                  : const Color(0xFF10B981).withOpacity(0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isScanning ? 'Place receipt here' : 'Scan complete!',
                                style: GoogleFonts.poppins(
                                  color: _isScanning ? Colors.white.withOpacity(0.2) : const Color(0xFF10B981),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Amber scanning beam
                      if (_isScanning) Positioned(
                        top: _beamAnim.value * 280 + 30,
                        left: 50, right: 50,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              const Color(0xFFF59E0B).withOpacity(0.9),
                              Colors.transparent,
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Corner brackets
                      ..._buildScanCorners(),
                      
                      // Status overlay
                      Positioned(
                        bottom: 16, left: 0, right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_isScanning ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isScanning) SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                                  ),
                                ),
                                if (_isScanning) const SizedBox(width: 8),
                                Text(
                                  _isScanning ? 'Reading receipt...' : '✓ Data extracted',
                                  style: GoogleFonts.poppins(
                                    color: _isScanning ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Results panel
          if (_result != null) AnimatedBuilder(
            animation: _resultCtrl,
            builder: (ctx, _) => Transform.translate(
              offset: Offset(0, _resultSlide.value),
              child: Opacity(
                opacity: _resultFade.value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                      const SizedBox(height: 16),
                      
                      // Title
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withOpacity(0.1),
                          ),
                          child: const Icon(Icons.document_scanner, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Extracted Data', style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18, fontWeight: FontWeight.w600,
                        )),
                      ]),
                      const SizedBox(height: 20),
                      
                      // Animated field reveals
                      _revealField(0, 'Date', _result!.date, Icons.calendar_today_outlined, isDark),
                      _revealField(1, 'Total Amount', 'RM ${_result!.amount.toStringAsFixed(2)}', Icons.attach_money, isDark),
                      _revealField(2, 'Merchant', _result!.merchant, Icons.store_outlined, isDark),
                      _revealField(3, 'Category', _result!.category, Icons.category_outlined, isDark),
                      
                      const SizedBox(height: 20),
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, _result),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF06B6D4) : const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text('Use This Data', style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revealField(int index, String label, String value, IconData icon, bool isDark) {
    final isVisible = _revealedFields > index;
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: GoogleFonts.poppins(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14,
                )),
              ),
              Text(value, style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14, fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScanCorners() {
    const color = Color(0xFFF59E0B);
    const s = 28.0;
    const w = 3.0;
    Widget cr(bool t, bool r, bool b, bool l) => Container(width: s, height: s, decoration: BoxDecoration(border: Border(
      top: t ? const BorderSide(color: color, width: w) : BorderSide.none,
      right: r ? const BorderSide(color: color, width: w) : BorderSide.none,
      bottom: b ? const BorderSide(color: color, width: w) : BorderSide.none,
      left: l ? const BorderSide(color: color, width: w) : BorderSide.none,
    )));
    return [
      Positioned(top: 16, left: 30, child: cr(true, false, false, true)),
      Positioned(top: 16, right: 30, child: cr(true, true, false, false)),
      Positioned(bottom: 50, left: 30, child: cr(false, false, true, true)),
      Positioned(bottom: 50, right: 30, child: cr(false, true, true, false)),
    ];
  }
}
