import 'package:flutter/material.dart';

class CustomSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const CustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        // Track: bg-muted (track) + bg-primary (active range)
        trackHeight: 6.0,
        trackShape: const RoundedRectSliderTrackShape(),
        activeTrackColor: Colors.white, // bg-primary
        inactiveTrackColor: Colors.white12, // bg-muted
        
        // Thumb: border-primary bg-background
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        thumbColor: const Color(0xFF020817), // bg-background
        overlayColor: Colors.white.withOpacity(0.2), // ring-ring/50
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}