import 'package:flutter/material.dart';

class CustomToggleGroup<T> extends StatelessWidget {
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final List<ButtonSegment<T>> segments;
  final bool multiSelectionEnabled;

  const CustomToggleGroup({
    super.key,
    required this.selected,
    required this.onSelectionChanged,
    required this.segments,
    this.multiSelectionEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: segments,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      style: SegmentedButton.styleFrom(
        // Shadcn-style: bg-background and border-input
        backgroundColor: const Color(0xFF020817),
        foregroundColor: Colors.white70,
        selectedBackgroundColor: const Color(0xFF1E293B), // bg-accent
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: Colors.white12), // border
      ),
    );
  }
}