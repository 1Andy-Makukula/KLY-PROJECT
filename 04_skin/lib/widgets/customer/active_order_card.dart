import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/alpha_buttons.dart';

// Placeholder for AlphaFlashButton if it doesn't exist yet, adapting from prompt context
class AlphaGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const AlphaGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(text),
    );
  }
}

class ActiveOrderCard extends StatelessWidget {
  final String shopName;
  final String orderId;
  final String pickupCode; // The "Hero" Data
  final String itemCount;
  final String totalPrice;
  final String status; // e.g., "Ready for Pickup"
  final VoidCallback onViewReceipt;

  const ActiveOrderCard({
    super.key,
    this.shopName =
        "Shop Name", // Defaults for backward compatibility if needed
    this.orderId = "0000",
    required this.pickupCode,
    this.itemCount = "1",
    this.totalPrice = "K 0.00",
    this.status = "Ready for Pickup",
    required this.onViewReceipt,
    // Add parameters from old signature if any, to avoid breaking changes if called elsewhere
    String? items,
    String? price,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(0), // Custom padding for inner layout
      child: Column(
        children: [
          // 1. Top Section: Shop & Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: AlphaTheme.heading.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Order #$orderId",
                      style: AlphaTheme.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusPill(status),
              ],
            ),
          ),

          // 2. The "Digital Ticket" Zone (Darker Glass)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), // Darker contrast zone
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "SECURE PICKUP CODE",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // The Code itself
                Text(
                  pickupCode,
                  style: const TextStyle(
                    color: AlphaTheme.primaryOrange, // High visibility
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4, // W i d e   t e x t
                    fontFamily: 'Courier', // Monospace for code look
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Section: Totals & Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$itemCount Items", style: AlphaTheme.body),
                    Text(
                      totalPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  height: 40,
                  child: AlphaGlassButton(
                    text: "Receipt",
                    onPressed: onViewReceipt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AlphaTheme.primaryOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AlphaTheme.primaryOrange.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AlphaTheme.primaryOrange.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AlphaTheme.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: AlphaTheme.primaryOrange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
