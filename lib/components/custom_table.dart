import 'package:flutter/material.dart';

class CustomDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // Shadcn-style: 0.5 opacity for header, dark borders
        headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
        dividerThickness: 1,
        columnSpacing: 24,
        columns: columns
            .map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ))
            .toList(),
        rows: rows.map((row) {
          return DataRow(
            // Shadcn-style: hover:bg-muted/50
            color: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered)) return Colors.white12;
              return null;
            }),
            cells: row
                .map((cell) => DataCell(
                      Text(cell, style: const TextStyle(color: Colors.white70)),
                    ))
                .toList(),
          );
        }).toList(),
      ),
    );
  }
}