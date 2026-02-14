import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';

class ScoreCard extends StatelessWidget {
  final int score;
  final String label;
  final String trend;

  const ScoreCard({
    super.key,
    required this.score,
    required this.label,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: GlassStyles.scoreCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Health Score",
                style: AlphaTheme.labelLarge.copyWith(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: AlphaTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "$score/100",
            style: AlphaTheme.headlineLarge.copyWith(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                trend,
                style: AlphaTheme.bodyMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
