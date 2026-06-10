import 'package:flutter/material.dart';

/// Gemini-inspired sparkle icon for the AI assistant tab.
class GeminiNavIcon extends StatelessWidget {
  final bool selected;
  final Color unselectedColor;
  final double size;

  const GeminiNavIcon({
    super.key,
    required this.selected,
    this.unselectedColor = const Color(0xFF8F9BB3),
    this.size = 24,
  });

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4285F4),
      Color(0xFF9B72CB),
      Color(0xFFD96570),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.auto_awesome,
      size: size,
      color: selected ? Colors.white : unselectedColor,
    );

    if (!selected) return icon;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => _gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: icon,
    );
  }
}
