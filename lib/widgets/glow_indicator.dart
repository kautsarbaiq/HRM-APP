import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlowIndicator extends StatefulWidget {
  final bool isActive;
  final String label;

  const GlowIndicator({
    super.key,
    required this.isActive,
    this.label = '',
  });

  @override
  State<GlowIndicator> createState() => _GlowIndicatorState();
}

class _GlowIndicatorState extends State<GlowIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: _animation.value,
                    spreadRadius: _animation.value / 4,
                  ),
                ],
              ),
            ),
            if (widget.label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
