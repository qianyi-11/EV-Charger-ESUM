import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
      // Colors matching Shadcn data-[state=checked]:bg-primary
      activeColor: Colors.white, // thumb color when active
      activeTrackColor: Colors.white, // track color when active (bg-primary)
      inactiveTrackColor: Colors.white24, // bg-switch-background
      inactiveThumbColor: Colors.white, // thumb color when inactive
      
      // Compact sizing to match "h-[1.15rem] w-8"
      // Flutter's Switch scale can be adjusted via transform
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}