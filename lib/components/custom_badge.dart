import 'package:flutter/material.dart';

enum BadgeVariant { defaultStyle, secondary, destructive, outline }

class CustomBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const CustomBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.defaultStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on the chosen variant
    Color backgroundColor;
    Color textColor;
    Color borderColor = Colors.transparent;

    switch (variant) {
      case BadgeVariant.defaultStyle:
        backgroundColor = Colors.white; // standard Shadcn dark mode primary
        textColor = Colors.black;
        break;
      case BadgeVariant.secondary:
        backgroundColor = const Color(0xFF1E293B); // Muted dark slate
        textColor = Colors.grey[300]!;
        break;
      case BadgeVariant.destructive:
        backgroundColor = Colors.red[800]!.withOpacity(0.8);
        textColor = Colors.white;
        break;
      case BadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = Colors.grey[300]!;
        borderColor = Colors.white24;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0), // px-2 py-0.5
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6.0), // rounded-md
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // shrink-0 / w-fit
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12, // [&>svg]:size-3
              color: textColor,
            ),
            const SizedBox(width: 4), // gap-1
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w500, // font-medium
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}