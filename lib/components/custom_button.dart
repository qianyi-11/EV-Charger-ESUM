import 'package:flutter/material.dart';

enum ButtonVariant { defaultStyle, destructive, outline, secondary, ghost, link }
enum ButtonSize { defaultSize, sm, lg, icon }

class CustomButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;

  const CustomButton({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.defaultStyle,
    this.size = ButtonSize.defaultSize,
    this.isLoading = false,
  }) : assert(text != null || icon != null, 'Button must have text or an icon');

  @override
  Widget build(BuildContext context) {
    // 1. Determine Dimensions based on Size Enum
    double height;
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case ButtonSize.sm:
        height = 32.0; // h-8
        padding = const EdgeInsets.symmetric(horizontal: 12.0); // px-3
        fontSize = 12.0;
        break;
      case ButtonSize.lg:
        height = 40.0; // h-10
        padding = const EdgeInsets.symmetric(horizontal: 24.0); // px-6
        fontSize = 14.0;
        break;
      case ButtonSize.icon:
        height = 36.0; // size-9
        padding = EdgeInsets.zero;
        fontSize = 14.0;
        break;
      case ButtonSize.defaultSize:
        height = 36.0; // h-9
        padding = const EdgeInsets.symmetric(horizontal: 16.0); // px-4
        fontSize = 14.0;
        break;
    }

    // 2. Build the inner content (Icon + Text + Loading Spinner)
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: variant == ButtonVariant.defaultStyle ? Colors.black : Colors.white,
            ),
          ),
          if (text != null && size != ButtonSize.icon) const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 16),
          if (text != null && size != ButtonSize.icon) const SizedBox(width: 8),
        ],
        if (text != null && size != ButtonSize.icon)
          Text(
            text!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              decoration: variant == ButtonVariant.link ? TextDecoration.underline : null,
            ),
          ),
      ],
    );

    // 3. Return the exact button type based on the Variant Enum
    switch (variant) {
      case ButtonVariant.outline:
        return SizedBox(
          height: height,
          width: size == ButtonSize.icon ? height : null,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ),
            child: buttonContent,
          ),
        );

      case ButtonVariant.ghost:
      case ButtonVariant.link:
        return SizedBox(
          height: height,
          width: size == ButtonSize.icon ? height : null,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              padding: padding,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ),
            child: buttonContent,
          ),
        );

      case ButtonVariant.destructive:
        return SizedBox(
          height: height,
          width: size == ButtonSize.icon ? height : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              padding: padding,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ),
            child: buttonContent,
          ),
        );

      case ButtonVariant.secondary:
        return SizedBox(
          height: height,
          width: size == ButtonSize.icon ? height : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B), // Muted dark slate
              foregroundColor: Colors.white,
              padding: padding,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ),
            child: buttonContent,
          ),
        );

      case ButtonVariant.defaultStyle:
        return SizedBox(
          height: height,
          width: size == ButtonSize.icon ? height : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Standard dark mode primary
              foregroundColor: Colors.black,
              padding: padding,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ),
            child: buttonContent,
          ),
        );
    }
  }
}