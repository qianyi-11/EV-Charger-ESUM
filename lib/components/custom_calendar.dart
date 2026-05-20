import 'package:flutter/material.dart';

class CustomCalendar extends StatelessWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateChanged;

  const CustomCalendar({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return Container(
      // The outer card styling matching your dark theme
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Matches your bg-card
        borderRadius: BorderRadius.circular(8.0), // rounded-md
        border: Border.all(color: Colors.white12), // border
      ),
      // We wrap the native calendar in a local Theme to force the colors
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white, // The background color of the selected day
            onPrimary: Colors.black, // The text color of the selected day
            surface: Color(0xFF0F172A), // The background of the calendar panel
            onSurface: Colors.white, // The default text color for standard days
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            titleSmall: TextStyle(fontWeight: FontWeight.w500), // Month header
          ),
        ),
        child: CalendarDatePicker(
          initialDate: initialDate ?? now,
          firstDate: firstDate ?? DateTime(now.year - 10),
          lastDate: lastDate ?? DateTime(now.year + 10),
          onDateChanged: (DateTime date) {
            if (onDateChanged != null) {
              onDateChanged!(date);
            }
          },
        ),
      ),
    );
  }
}