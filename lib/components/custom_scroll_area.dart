import 'package:flutter/material.dart';

class CustomScrollArea extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const CustomScrollArea({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // The Scrollbar widget handles the "thumb" appearance natively
    return Scrollbar(
      controller: controller,
      // Forces the scrollbar to be visible, matching the Shadcn design philosophy
      thumbVisibility: true, 
      thickness: 6.0,
      radius: const Radius.circular(99.0), // rounded-full equivalent
      child: SingleChildScrollView(
        controller: controller,
        // Removes the default native glow effect to keep the UI clean
        physics: const BouncingScrollPhysics(), 
        child: child,
      ),
    );
  }
}