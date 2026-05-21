import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final List<BoxShadow>? shadows;
  final Color? borderColor;
  final Color? bgColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 12.0,
    this.shadows,
    this.borderColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final roundedRadius = borderRadius ?? BorderRadius.circular(16);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: roundedRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor ?? AppColors.glassBg,
              borderRadius: roundedRadius,
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
