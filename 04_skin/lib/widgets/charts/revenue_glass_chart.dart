import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../glass_card.dart';

class RevenueGlassChart extends StatelessWidget {
  const RevenueGlassChart({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Revenue History",
            style: AlphaTheme.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.70,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Colors.black.withOpacity(0.8), // Darker for readability
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()}k',
                        const TextStyle(
                          color: KithLyColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mn';
                            break;
                          case 1:
                            text = 'Tu';
                            break;
                          case 2:
                            text = 'Wd';
                            break;
                          case 3:
                            text = 'Th';
                            break;
                          case 4:
                            text = 'Fr';
                            break;
                          case 5:
                            text = 'Sa';
                            break;
                          case 6:
                            text = 'Su';
                            break;
                          default:
                            text = '';
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(text, style: style),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 28,
                      interval: 5,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 5),
                  _makeGroupData(1, 6.5),
                  _makeGroupData(2, 5),
                  _makeGroupData(3, 7.5),
                  _makeGroupData(4, 9),
                  _makeGroupData(5, 11.5),
                  _makeGroupData(6, 6.5),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [KithLyColors.gold, KithLyColors.orange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 15, // Max Y
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
}
