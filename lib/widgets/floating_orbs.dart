import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FloatingOrbsBackground extends StatefulWidget {
  final Widget? child;

  const FloatingOrbsBackground({super.key, this.child});

  @override
  State<FloatingOrbsBackground> createState() => _FloatingOrbsBackgroundState();
}

class _FloatingOrbsBackgroundState extends State<FloatingOrbsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_OrbModel> _orbs = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Initialize 20 distinct floating orbs
    final random = math.Random(42); // Seed for consistency
    for (int i = 0; i < 20; i++) {
      final size = random.nextDouble() * 120 + 80; // size 80 to 200
      final color = i % 3 == 0
          ? AppColors.electricBlue.withOpacity(0.08)
          : i % 3 == 1
              ? AppColors.dangerRed.withOpacity(0.04)
              : const Color(0xFF8A2BE2).withOpacity(0.06); // violet
      
      _orbs.add(
        _OrbModel(
          baseX: random.nextDouble(),
          baseY: random.nextDouble(),
          radius: size / 2,
          color: color,
          speedX: (random.nextDouble() - 0.5) * 0.15,
          speedY: (random.nextDouble() - 0.5) * 0.15,
          phaseOffset: random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The background painting canvas
        Positioned.fill(
          child: Container(
            color: AppColors.background,
          ),
        ),
        // Draw the orbs dynamically
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _OrbsPainter(
                  orbs: _orbs,
                  progress: _controller.value,
                ),
              );
            },
          ),
        ),
        // Foreground Content
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _OrbModel {
  final double baseX; // fraction of screen width
  final double baseY; // fraction of screen height
  final double radius;
  final Color color;
  final double speedX;
  final double speedY;
  final double phaseOffset;

  _OrbModel({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.phaseOffset,
  });
}

class _OrbsPainter extends CustomPainter {
  final List<_OrbModel> orbs;
  final double progress;

  _OrbsPainter({required this.orbs, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      // Calculate current position based on trigonometric loops
      final angle = progress * math.pi * 2 + orb.phaseOffset;
      
      final currentX = orb.baseX * size.width + math.sin(angle) * (size.width * orb.speedX);
      final currentY = orb.baseY * size.height + math.cos(angle) * (size.height * orb.speedY);
      
      final center = Offset(currentX, currentY);
      
      // Draw radial gradient orb to achieve the glowing fog effect
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color,
            orb.color.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: orb.radius),
        );

      canvas.drawCircle(center, orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter oldDelegate) => true;
}
