import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final Color lineColor;
  final String? tooltipLabel;

  const CustomLineChart({
    super.key,
    required this.dataPoints,
    this.lineColor = Colors.white, // Matches Shadcn dark primary
    this.tooltipLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Convert your simple list of numbers into the FlSpot format the chart needs
    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return AspectRatio(
      aspectRatio: 16 / 9, // aspect-video
      child: LineChart(
        LineChartData(
          // 1. Grid Styling (Muted horizontal lines, no vertical lines)
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Colors.white12, // stroke-border/50
                strokeWidth: 1,
              );
            },
          ),

          // 2. Axis & Label Styling
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta, // <-- UPDATED FOR THE NEWEST PACKAGE VERSION
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey[400], // fill-muted-foreground
                        fontSize: 12, // text-xs
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ),
          ),

          // 3. Border styling (hide the outer box)
          borderData: FlBorderData(show: false),

          // 4. The actual line and dot styling
          lineBarsData: [
            LineChartBarData(
              spots: spots, 
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), // Hides dots until touched
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1), 
              ),
            ),
          ],

          // 5. Interactive Tooltip Styling
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E293B), // Dark Slate
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  return LineTooltipItem(
                    '${tooltipLabel ?? 'Value'}: ${touchedSpot.y}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}