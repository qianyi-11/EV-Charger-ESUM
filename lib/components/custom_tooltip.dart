import 'package:flutter/material.dart';

class CustomTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const CustomTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      // Matches the Shadcn "bg-primary" (e.g., white background in dark mode)
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(6.0), // rounded-md
      ),
      // Matches "text-primary-foreground" (dark text on white)
      textStyle: const TextStyle(
        color: Colors.black, 
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
      preferBelow: true,
      child: child,
    );
  }
}