import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../glass_card.dart';

class RevenueGlassChart extends StatefulWidget {
  const RevenueGlassChart({super.key});

  @override
  State<RevenueGlassChart> createState() => _RevenueGlassChartState();
}

class _RevenueGlassChartState extends State<RevenueGlassChart> {
  // Simulating "touched" state to show tooltips
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Revenue",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "K 12,450.00",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Trend Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50), // Green for money
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "+12%",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 2. The Holographic Chart
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          Colors.black.withOpacity(0.8), // Glassy background
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.all(12),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${getMethodName(group.x.toInt())}\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'K ${(rod.toY - 1).toStringAsFixed(0)}k', // Removing the base offset
                              style: const TextStyle(
                                color: KithLyColors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex =
                            barTouchResponse.spot!.touchedBarGroupIndex;
                      });
                    },
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
                        getTitlesWidget: getTitles,
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: showingGroups(),
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
      ),
    );
  }

  // Helper to generate the gradient bars
  List<BarChartGroupData> showingGroups() => List.generate(7, (i) {
    // Mock data logic
    double value = [5, 12, 8, 4, 14, 10, 16][i].toDouble();

    return makeGroupData(i, value, isTouched: i == touchedIndex);
  });

  BarChartGroupData makeGroupData(int x, double y, {bool isTouched = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y, // Pop up effect on touch
          gradient: const LinearGradient(
            colors: [KithLyColors.orange, KithLyColors.gold],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20, // Max height
            color: Colors.white.withOpacity(0.05), // Ghost track
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white54,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('M', style: style);
        break;
      case 1:
        text = const Text('T', style: style);
        break;
      case 2:
        text = const Text('W', style: style);
        break;
      case 3:
        text = const Text('T', style: style);
        break;
      case 4:
        text = const Text('F', style: style);
        break;
      case 5:
        text = const Text('S', style: style);
        break;
      case 6:
        text = const Text('S', style: style);
        break;
      default:
        text = const Text('', style: style);
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 16, child: text);
  }

  String getMethodName(int index) {
    switch (index) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return '';
    }
  }
}
