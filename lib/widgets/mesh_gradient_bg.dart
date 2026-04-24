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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF334155), Color(0xFF1E293B)],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _LightMeshPainter(_controller.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _LightMeshPainter extends CustomPainter {
  final double animationValue;
  _LightMeshPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Soft cyan blob
    final c1 = Offset(
      size.width * (0.25 + 0.15 * math.sin(animationValue * 2 * math.pi)),
      size.height * (0.15 + 0.1 * math.cos(animationValue * 2 * math.pi)),
    );
    paint.shader = RadialGradient(colors: [const Color(0xFF06B6D4).withOpacity(0.08), const Color(0xFF06B6D4).withOpacity(0.0)])
        .createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5));
    canvas.drawCircle(c1, size.width * 0.5, paint);
    // Soft purple blob
    final c2 = Offset(
      size.width * (0.75 + 0.1 * math.cos(animationValue * 2 * math.pi + 1.5)),
      size.height * (0.55 + 0.12 * math.sin(animationValue * 2 * math.pi + 1.5)),
    );
    paint.shader = RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.06), const Color(0xFF8B5CF6).withOpacity(0.0)])
        .createShader(Rect.fromCircle(center: c2, radius: size.width * 0.45));
    canvas.drawCircle(c2, size.width * 0.45, paint);
    // Soft amber blob
    final c3 = Offset(
      size.width * (0.5 + 0.18 * math.sin(animationValue * 2 * math.pi + 3.0)),
      size.height * (0.85 + 0.06 * math.cos(animationValue * 2 * math.pi + 3.0)),
    );
    paint.shader = RadialGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.05), const Color(0xFFF59E0B).withOpacity(0.0)])
        .createShader(Rect.fromCircle(center: c3, radius: size.width * 0.4));
    canvas.drawCircle(c3, size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant _LightMeshPainter old) => old.animationValue != animationValue;
}
