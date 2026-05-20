import 'package:flutter/material.dart';

class CustomToggle extends StatelessWidget {
  final bool isPressed;
  final ValueChanged<bool> onPressed;
  final Widget child;

  const CustomToggle({
    super.key,
    required this.isPressed,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onPressed(!isPressed),
      borderRadius: BorderRadius.circular(6.0), // rounded-md
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFF1E293B) : Colors.transparent, // bg-accent
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isPressed ? Colors.transparent : Colors.white12, // border-input
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: isPressed ? Colors.white : Colors.white70, // text-accent-foreground
            fontSize: 14,
          ),
          child: child,
        ),
      ),
    );
  }
}