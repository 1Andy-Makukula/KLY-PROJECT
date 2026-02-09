/// =============================================================================
/// KithLy Global Protocol - REVENUE CARD (Phase IV-Extension)
/// revenue_card.dart - Shop Revenue HUD with LineChart
/// =============================================================================
/// 
/// Revenue HUD matching RevenueChart.tsx aesthetic:
/// - Gradient fill under the line (Green to Transparent)
/// - No grid lines, "floating" look
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/alpha_theme.dart';

/// Revenue HUD Card with LineChart
class RevenueCard extends StatelessWidget {
  final double todayRevenue;
  final List<double> weeklyData;
  final bool isLoading;
  
  const RevenueCard({
    super.key,
    required this.todayRevenue,
    required this.weeklyData,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_ZM',
      symbol: 'K',
      decimalDigits: 0,
    );
    
    return Container(
      decoration: AlphaTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Revenue',
                      style: AlphaTheme.bodyText,
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? _buildLoadingAmount()
                        : Text(
                            currencyFormat.format(todayRevenue),
                            style: AlphaTheme.currencyLarge,
                          ),
                  ],
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentGreen.withOpacity(0.2),
                    borderRadius: AlphaTheme.chipRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AlphaTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AlphaTheme.accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chart
          SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              child: isLoading
                  ? _buildLoadingChart()
                  : _buildRevenueChart(),
            ),
          ),
          
          // Footer - Week summary
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last 7 days',
                  style: AlphaTheme.captionText,
                ),
                Text(
                  'Total: ${currencyFormat.format(_weekTotal)}',
                  style: TextStyle(
                    color: AlphaTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingAmount() {
    return Container(
      width: 120,
      height: 36,
      decoration: BoxDecoration(
        color: AlphaTheme.backgroundGlass,
        borderRadius: AlphaTheme.chipRadius,
      ),
    );
  }
  
  Widget _buildLoadingChart() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          AlphaTheme.accentGreen.withOpacity(0.5),
        ),
        strokeWidth: 2,
      ),
    );
  }
  
  double get _weekTotal => weeklyData.fold(0, (sum, val) => sum + val);
  
  double get _maxY {
    if (weeklyData.isEmpty) return 100;
    final max = weeklyData.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.2 : 100;
  }
  
  Widget _buildRevenueChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: _maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AlphaTheme.accentGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Only show dot for today (last point)
                if (index == weeklyData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: AlphaTheme.accentGreen,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: AlphaTheme.revenueGradient,
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final format = NumberFormat.currency(
                  symbol: 'K',
                  decimalDigits: 0,
                );
                return LineTooltipItem(
                  format.format(spot.y),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  List<FlSpot> _getSpots() {
    if (weeklyData.isEmpty) {
      return [const FlSpot(0, 0), const FlSpot(6, 0)];
    }
    
    return weeklyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }
}
