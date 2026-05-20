import 'package:flutter/material.dart';

class CustomProgress extends StatelessWidget {
  final double value; // Expects a value from 0.0 to 100.0
  final double height;
  final Color? backgroundColor;
  final Color? color;

  const CustomProgress({
    super.key,
    required this.value,
    this.height = 8.0, // Matches Shadcn h-2
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the value never exceeds 100 or drops below 0, then convert to a percentage decimal
    final double fraction = (value.clamp(0.0, 100.0)) / 100.0;

    return Container(
      height: height,
      width: double.infinity, // w-full
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2), // bg-primary/20
        borderRadius: BorderRadius.circular(999.0), // rounded-full
      ),
      alignment: Alignment.centerLeft, // Ensures the fill starts strictly from the left
      child: LayoutBuilder(
        builder: (context, constraints) {
          // AnimatedContainer automatically transitions when the width changes
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: height,
            width: constraints.maxWidth * fraction,
            decoration: BoxDecoration(
              color: color ?? Colors.white, // bg-primary
              borderRadius: BorderRadius.circular(999.0), // rounded-full
            ),
          );
        },
      ),
    );
  }
}