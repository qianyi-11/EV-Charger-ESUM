import 'package:flutter/material.dart';

class CustomFormItem extends StatelessWidget {
  final String label;
  final Widget child; // The actual input field goes here
  final String? description;
  final String? errorText;

  const CustomFormItem({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    // Shadcn turns the label red if there is an active error
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. FormLabel
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hasError ? Colors.red[400] : Colors.white,
          ),
        ),
        const SizedBox(height: 8.0), // gap-2
        
        // 2. FormControl (The Input Field)
        child, 
        
        // 3. FormDescription or FormMessage (Error takes priority)
        if (hasError) ...[
          const SizedBox(height: 6.0),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 13, // text-sm
              fontWeight: FontWeight.w500,
              color: Colors.red[400], // text-destructive
            ),
          ),
        ] else if (description != null) ...[
          const SizedBox(height: 6.0),
          Text(
            description!,
            style: TextStyle(
              fontSize: 13, // text-sm
              color: Colors.grey[400], // text-muted-foreground
            ),
          ),
        ],
      ],
    );
  }
}