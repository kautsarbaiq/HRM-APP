import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const QuickActionCard({super.key, required this.icon, required this.label, required this.color, required this.onTap});
  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(animation: _scale, builder: (ctx, child) => Transform.scale(scale: _scale.value, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                boxShadow: [BoxShadow(color: widget.color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [widget.color.withOpacity(0.15), widget.color.withOpacity(0.05)])),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(widget.label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
