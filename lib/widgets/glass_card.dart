import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 25.0,
    this.opacity = 0.4,
    this.padding,
    this.margin,
    this.borderWidth = 1.0,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _scaleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sigma = isDark ? widget.blurSigma : 35.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => _scaleCtrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _scaleCtrl.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _scaleCtrl.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (ctx, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Base glass fill
                  color: isDark
                      ? const Color(0xFF0F172A).withOpacity(0.2)
                      : Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFE2E8F0),
                    width: isDark ? widget.borderWidth : 1.0,
                  ),
                  // Inner glow + edge lighting shadows
                  boxShadow: [
                    // Primary depth shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    // Subtle close shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    // Apple-style inset top highlight (simulated with a negative offset glow)
                    if (!isDark) BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 1,
                      spreadRadius: -1,
                      offset: const Offset(0, -0.5),
                    ),
                  ],
                  // Light mode inner glow gradient
                  gradient: isDark ? null : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.45),
                      Colors.white.withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
