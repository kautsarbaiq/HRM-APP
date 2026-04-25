import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeshGradientBg extends StatefulWidget {
  final Widget child;
  const MeshGradientBg({super.key, required this.child});
  @override
  State<MeshGradientBg> createState() => _MeshGradientBgState();
}

class _MeshGradientBgState extends State<MeshGradientBg> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF020617)]
                : [const Color(0xFFFFFFFF), const Color(0xFFFCFCFD), const Color(0xFFF8FAFC)],
            ),
          ),
          child: CustomPaint(
            painter: _MeshPainter(_controller.value, isDark),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  _MeshPainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final t = animationValue * 2 * math.pi;
    
    if (isDark) {
      // === DARK MODE: Vibrant cyan / purple / amber ===
      // Cyan blob
      final c1 = Offset(
        size.width * (0.25 + 0.15 * math.sin(t)),
        size.height * (0.15 + 0.1 * math.cos(t)),
      );
      paint.shader = RadialGradient(colors: [const Color(0xFF06B6D4).withOpacity(0.12), const Color(0xFF06B6D4).withOpacity(0.0)])
          .createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5));
      canvas.drawCircle(c1, size.width * 0.5, paint);
      
      // Purple blob
      final c2 = Offset(
        size.width * (0.75 + 0.1 * math.cos(t + 1.5)),
        size.height * (0.55 + 0.12 * math.sin(t + 1.5)),
      );
      paint.shader = RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.09), const Color(0xFF8B5CF6).withOpacity(0.0)])
          .createShader(Rect.fromCircle(center: c2, radius: size.width * 0.45));
      canvas.drawCircle(c2, size.width * 0.45, paint);
      
      // Amber blob
      final c3 = Offset(
        size.width * (0.5 + 0.18 * math.sin(t + 3.0)),
        size.height * (0.85 + 0.06 * math.cos(t + 3.0)),
      );
      paint.shader = RadialGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.07), const Color(0xFFF59E0B).withOpacity(0.0)])
          .createShader(Rect.fromCircle(center: c3, radius: size.width * 0.4));
      canvas.drawCircle(c3, size.width * 0.4, paint);
    } else {
      // === LIGHT MODE: Soft pastels — lavender, mint, peach, rose ===
      
      // Lavender blob (top-left drift)
      final c1 = Offset(
        size.width * (0.2 + 0.12 * math.sin(t)),
        size.height * (0.12 + 0.08 * math.cos(t)),
      );
      paint.shader = RadialGradient(colors: [
        const Color(0xFFC4B5FD).withOpacity(0.12), // lavender-300
        const Color(0xFFC4B5FD).withOpacity(0.0),
      ]).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5));
      canvas.drawCircle(c1, size.width * 0.5, paint);
      
      // Mint blob (center-right drift)
      final c2 = Offset(
        size.width * (0.78 + 0.1 * math.cos(t + 1.2)),
        size.height * (0.35 + 0.1 * math.sin(t + 1.2)),
      );
      paint.shader = RadialGradient(colors: [
        const Color(0xFF6EE7B7).withOpacity(0.10), // emerald-300
        const Color(0xFF6EE7B7).withOpacity(0.0),
      ]).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.45));
      canvas.drawCircle(c2, size.width * 0.45, paint);
      
      // Peach blob (bottom-left drift)
      final c3 = Offset(
        size.width * (0.35 + 0.15 * math.sin(t + 2.5)),
        size.height * (0.75 + 0.06 * math.cos(t + 2.5)),
      );
      paint.shader = RadialGradient(colors: [
        const Color(0xFFFDA4AF).withOpacity(0.08), // rose-300
        const Color(0xFFFDA4AF).withOpacity(0.0),
      ]).createShader(Rect.fromCircle(center: c3, radius: size.width * 0.42));
      canvas.drawCircle(c3, size.width * 0.42, paint);
      
      // Rose gold blob (bottom-right, 4th blob)
      final c4 = Offset(
        size.width * (0.7 + 0.1 * math.cos(t + 4.0)),
        size.height * (0.88 + 0.05 * math.sin(t + 4.0)),
      );
      paint.shader = RadialGradient(colors: [
        const Color(0xFFFBCFE8).withOpacity(0.10), // pink-200
        const Color(0xFFFBCFE8).withOpacity(0.0),
      ]).createShader(Rect.fromCircle(center: c4, radius: size.width * 0.38));
      canvas.drawCircle(c4, size.width * 0.38, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.animationValue != animationValue || old.isDark != isDark;
}
