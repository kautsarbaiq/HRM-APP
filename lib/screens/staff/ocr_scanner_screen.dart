import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

  bool _isScanning = false;
  bool _isWaiting = true; // waiting for user to pick source
  ReceiptData? _result;
  int _revealedFields = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _beamCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _beamAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _beamCtrl, curve: Curves.easeInOut));
    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultSlide = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut));
    _resultFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut));
    _beamCtrl.stop();
  }

  void _startScan(ImageSource source) async {
    setState(() { _isWaiting = false; _isScanning = true; _errorMessage = null; _result = null; _revealedFields = 0; });
    _beamCtrl.repeat();
    _resultCtrl.reset();

    final result = await OcrService.scanReceipt(source: source);
    if (!mounted) return;

    if (result == null) {
      // User cancelled image picker
      setState(() { _isScanning = false; _isWaiting = true; });
      _beamCtrl.stop();
      return;
    }

    if (result.amount == 0 && result.merchant == 'Unknown Merchant') {
      setState(() { _isScanning = false; _errorMessage = 'Could not extract data. Try a clearer image.'; });
      _beamCtrl.stop();
      return;
    }

    _beamCtrl.stop();
    setState(() { _isScanning = false; _result = result; });
    _resultCtrl.forward();
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
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 24), onPressed: () => Navigator.pop(context)),
        title: Text('Scan Receipt', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Scanner viewport
        Expanded(
          flex: _result == null ? 3 : 2,
          child: AnimatedBuilder(
            animation: _beamAnim,
            builder: (ctx, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [
                Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const RadialGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], radius: 1.2))),
                Center(child: Container(
                  width: 220, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (_isScanning ? const Color(0xFFF59E0B) : _result != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8)).withOpacity(0.5), width: 2),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      _result != null ? Icons.check_circle_outline : _errorMessage != null ? Icons.error_outline : Icons.receipt_long,
                      size: 48, color: _result != null ? const Color(0xFF10B981).withOpacity(0.6) : _errorMessage != null ? const Color(0xFFEF4444).withOpacity(0.6) : Colors.white.withOpacity(0.1),
                    ),
                    const SizedBox(height: 12),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(
                      _result != null ? 'Scan complete!' : _errorMessage ?? (_isScanning ? 'Reading receipt...' : 'Select image source below'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: _result != null ? const Color(0xFF10B981) : _errorMessage != null ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.2), fontSize: 13),
                    )),
                  ]),
                )),
                if (_isScanning) Positioned(top: _beamAnim.value * 280 + 30, left: 50, right: 50, child: Container(height: 3, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFFF59E0B).withOpacity(0.9), Colors.transparent]),
                  boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 16, spreadRadius: 6)],
                ))),
                ..._buildScanCorners(),
                if (_isScanning) Positioned(bottom: 16, left: 0, right: 0, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)))),
                    const SizedBox(width: 8),
                    Text('Processing image...', style: GoogleFonts.poppins(color: const Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                ))),
              ])),
            ),
          ),
        ),

        // Source picker buttons (when waiting or error)
        if (_isWaiting || _errorMessage != null) Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(children: [
            Expanded(child: _sourceButton(Icons.camera_alt_outlined, 'Camera', () => _startScan(ImageSource.camera), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _sourceButton(Icons.photo_library_outlined, 'Gallery', () => _startScan(ImageSource.gallery), isDark)),
          ]),
        ),

        // Results panel
        if (_result != null) AnimatedBuilder(
          animation: _resultCtrl,
          builder: (ctx, _) => Transform.translate(offset: Offset(0, _resultSlide.value), child: Opacity(opacity: _resultFade.value, child: Container(
            width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withOpacity(0.1)),
                  child: const Icon(Icons.document_scanner, color: Color(0xFF10B981), size: 20)),
                const SizedBox(width: 12),
                Text('Extracted Data', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 20),
              _revealField(0, 'Date', _result!.date, Icons.calendar_today_outlined, isDark),
              _revealField(1, 'Total Amount', 'RM ${_result!.amount.toStringAsFixed(2)}', Icons.attach_money, isDark),
              _revealField(2, 'Merchant', _result!.merchant, Icons.store_outlined, isDark),
              _revealField(3, 'Category', _result!.category, Icons.category_outlined, isDark),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: SizedBox(height: 52, child: OutlinedButton(
                  onPressed: () { setState(() { _result = null; _isWaiting = true; _errorMessage = null; }); },
                  style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Rescan', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w600)),
                ))),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 52, child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _result),
                  style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF06B6D4) : const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: Text('Use This Data', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ))),
              ]),
            ]),
          ))),
        ),
      ]),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.5),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFF59E0B).withOpacity(0.08), const Color(0xFFF59E0B).withOpacity(0.02)]),
          ),
          child: Column(children: [
            Icon(icon, color: const Color(0xFFF59E0B), size: 32),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _revealField(int index, String label, String value, IconData icon, bool isDark) {
    final isVisible = _revealedFields > index;
    return AnimatedOpacity(opacity: isVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(offset: isVisible ? Offset.zero : const Offset(0, 0.3), duration: const Duration(milliseconds: 300),
        child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          Icon(icon, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14))),
          Flexible(child: Text(value, style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ])),
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
