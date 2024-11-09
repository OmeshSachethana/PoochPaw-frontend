import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';

class LineChartSample2 extends StatelessWidget {
  final List<FlSpot> spots;

  LineChartSample2({required this.spots});

  @override
  Widget build(BuildContext context) {
    double maxX = spots.isNotEmpty
        ? spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b)
        : 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              axisNameWidget: Text('Weeks'),
              axisNameSize: 16,
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value.toInt().toString()),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text('Rating'),
              axisNameSize: 16,
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(value.toInt().toString()),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          minX: 0,
          maxX: maxX,
          minY: 1,
          maxY: 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(nav),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: const Color(nav),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(nav).withOpacity(0.3),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black54,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((barSpot) {
                  final flSpot = barSpot;
                  return LineTooltipItem(
                    'Week ${flSpot.x.toInt()}: Rating ${flSpot.y}',
                    TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
            touchCallback:
                (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (touchResponse == null || touchResponse.lineBarSpots == null) {
                return;
              }
              for (var spot in touchResponse.lineBarSpots!) {
                print('Touched spot: (${spot.x}, ${spot.y})');
              }
            },
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}
