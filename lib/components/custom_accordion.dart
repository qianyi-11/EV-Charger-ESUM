import 'package:flutter/material.dart';

class CustomAccordion extends StatelessWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;

  const CustomAccordion({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Removes standard Flutter tile lines
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white12, // Matches the Tailwind "border-b"
              width: 1.0,
            ),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white, // Matches the dark mode text
            ),
          ),
          // Matches the chevron rotation styling from the React file
          iconColor: Colors.grey[400],
          collapsedIconColor: Colors.grey[400],
          childrenPadding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
          expandedAlignment: Alignment.topLeft,
          children: [
            // The expanding content
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}