import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlurRadius;
  final double minBlurRadius;
  final Duration duration;
  final bool animate;

  const PulsingGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.electricBlue,
    this.maxBlurRadius = 24.0,
    this.minBlurRadius = 8.0,
    this.duration = const Duration(seconds: 2),
    this.animate = true,
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double scale = 1.0 + (_controller.value * 0.02);
        final double blurRadius = widget.minBlurRadius +
            (_controller.value * (widget.maxBlurRadius - widget.minBlurRadius));

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.12 + (_controller.value * 0.18)),
                  blurRadius: blurRadius,
                  spreadRadius: 1 + (_controller.value * 2),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
