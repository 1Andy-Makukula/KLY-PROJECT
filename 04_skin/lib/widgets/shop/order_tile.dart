import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../glass_card.dart';

class OrderTile extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String items; // e.g., "2x Bread, 1x Milk"
  final String status; // "PAID", "DISPATCH", "COLLECTED"
  final String avatarUrl;
  final VoidCallback? onAction;

  const OrderTile({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.items,
    required this.status,
    required this.avatarUrl,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = KithLyColors.orange;
    String actionLabel = "Prepare";

    if (status == "DISPATCH") {
      statusColor = Colors.blue;
      actionLabel = "Mark Collected";
    } else if (status == "COLLECTED") {
      statusColor = KithLyColors.emerald;
      actionLabel = "Details";
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Colors.white24,
            onBackgroundImageError: (_, __) => const Icon(Icons.person),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(customerName, style: AlphaTheme.labelLarge),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  orderId,
                  style: AlphaTheme.bodyMedium.copyWith(fontSize: 12),
                ),
                Text(
                  items,
                  style: AlphaTheme.bodyMedium.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action Button
          if (status != "COLLECTED")
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(actionLabel),
            )
          else
            const Icon(Icons.check_circle, color: KithLyColors.emerald),
        ],
      ),
    );
  }
}
