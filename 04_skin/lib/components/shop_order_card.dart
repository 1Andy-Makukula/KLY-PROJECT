import 'package:flutter/material.dart';
import '../theme/alpha_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/alpha_buttons.dart';

class ShopOrderCard extends StatelessWidget {
  final String orderId;
  final String itemName;
  final String customerName;
  final String timeReceived;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ShopOrderCard({
    super.key,
    required this.orderId,
    required this.itemName,
    required this.customerName,
    required this.timeReceived,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Order ID and Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AlphaTheme.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AlphaTheme.orange.withOpacity(0.5)),
                ),
                child: Text(
                  '#$orderId',
                  style: AlphaTheme.labelLarge.copyWith(
                    color: AlphaTheme.orange,
                  ),
                ),
              ),
              Text(timeReceived, style: AlphaTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Item Details
          Text(itemName, style: AlphaTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'For: $customerName',
            style: AlphaTheme.bodyLarge.copyWith(color: Colors.white70),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AlphaGlassButton(text: 'Decline', onPressed: onDecline),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AlphaPrimaryButton(
                  text: 'Accept Order',
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
