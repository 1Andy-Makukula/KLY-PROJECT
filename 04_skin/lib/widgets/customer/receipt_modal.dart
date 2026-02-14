import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/glass_card.dart';

class ReceiptModal extends StatelessWidget {
  final String orderId;
  final String shopName;
  final String total;
  final List<Map<String, String>> items;

  const ReceiptModal({
    super.key,
    required this.orderId,
    required this.shopName,
    required this.total,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KithLyColors.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: KithLyColors.emerald.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: KithLyColors.emerald,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Payment Success", style: AlphaTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(orderId, style: AlphaTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Receipt Card
                GlassCard(
                  child: Column(
                    children: [
                      _buildRow("Shop", shopName),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white12),
                      ),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildRow(item['name']!, item['price']!),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white12),
                      ),
                      _buildRow("Total Paid", total, isBold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Share Receipt",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KithLyColors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Done",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AlphaTheme.labelLarge
              : AlphaTheme.bodyMedium.copyWith(color: Colors.white70),
        ),
        Text(
          value,
          style: isBold
              ? AlphaTheme.labelLarge.copyWith(color: KithLyColors.gold)
              : AlphaTheme.bodyMedium,
        ),
      ],
    );
  }
}
