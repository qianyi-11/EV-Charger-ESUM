import 'package:flutter/material.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDisabled;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    // If no onChanged function is provided, we treat it as disabled
    final bool disabled = isDisabled || onChanged == null;

    return GestureDetector(
      onTap: disabled ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 16.0, // size-4
        height: 16.0, // size-4
        decoration: BoxDecoration(
          color: value
              ? (disabled ? Colors.white54 : Colors.white) // data-[state=checked]:bg-primary
              : Colors.transparent, // Default unselected background
          borderRadius: BorderRadius.circular(4.0), // rounded-[4px]
          border: Border.all(
            color: value
                ? Colors.transparent
                : (disabled ? Colors.white24 : Colors.white54), // Subtle border for unselected
            width: 1.2,
          ),
        ),
        // The checkmark icon only appears when the value is true
        child: value
            ? Icon(
                Icons.check,
                size: 14.0, // size-3.5
                color: disabled ? Colors.black54 : Colors.black, // text-primary-foreground
              )
            : null,
      ),
    );
  }
}