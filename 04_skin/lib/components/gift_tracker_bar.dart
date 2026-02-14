import 'package:flutter/material.dart';
import '../theme/alpha_theme.dart';
import '../widgets/glass_container.dart';

class GiftTrackerBar extends StatelessWidget {
  final int currentStatus;

  const GiftTrackerBar({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'status': 100, 'label': 'Draft'},
      {'status': 200, 'label': 'Paid'},
      {'status': 300, 'label': 'Baking'},
      {'status': 400, 'label': 'Ready'},
      {'status': 420, 'label': 'Delivering'},
      {'status': 500, 'label': 'Delivered'},
    ];

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final stepStatus = step['status'] as int;
          final isCompleted = currentStatus >= stepStatus;
          final isCurrent = currentStatus == stepStatus;
          final isLast = index == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Line and Dot
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isCompleted ? AlphaTheme.gold : Colors.white24,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: AlphaTheme.orange, width: 2)
                            : null,
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: AlphaTheme.gold.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted ? AlphaTheme.gold : Colors.white10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Status Label
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'] as String,
                          style: isCompleted
                              ? AlphaTheme.labelLarge.copyWith(
                                  color: AlphaTheme.gold,
                                )
                              : AlphaTheme.bodyMedium,
                        ),
                        if (isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Current Status',
                              style: AlphaTheme.bodyMedium.copyWith(
                                color: AlphaTheme.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
