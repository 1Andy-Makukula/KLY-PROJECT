import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/glass_card.dart';

class OrderHistoryTile extends StatelessWidget {
  final String shopName;
  final String date;
  final String price;
  final String status;
  final VoidCallback onTap;

  const OrderHistoryTile({
    super.key,
    required this.shopName,
    required this.date,
    required this.price,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final Color statusColor = status == "DELIVERED"
        ? KithLyColors.emerald
        : (status == "CANCELLED" ? KithLyColors.alert : Colors.white54);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      animateOnHover: true,
      child: Row(
        children: [
          // Icon Placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName, style: AlphaTheme.labelLarge),
                Text(
                  date,
                  style: AlphaTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          // Price & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AlphaTheme.labelLarge.copyWith(color: KithLyColors.gold),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
