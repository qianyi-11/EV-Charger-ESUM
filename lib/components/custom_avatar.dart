import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 40.0, // Matches Tailwind's size-10
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1E293B), // Matches Tailwind bg-muted (Dark Slate)
      ),
      clipBehavior: Clip.antiAlias, // Ensures the image is perfectly round
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // If no image is provided, immediately show the fallback initials
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    // Try to load the image, but gracefully fallback if the link is dead
    return Image.network(
      imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        fallbackText,
        style: TextStyle(
          color: Colors.white70,
          fontSize: size * 0.4, // Automatically scales the text to fit the circle
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}