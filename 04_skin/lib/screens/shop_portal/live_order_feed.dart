/// =============================================================================
/// KithLy Global Protocol - LIVE ORDER FEED (Phase IV-Extension)
/// live_order_feed.dart - Status 300 Orders with Swipe Actions
/// =============================================================================
/// 
/// Displays orders ready for collection (Status 300).
/// Swipe-to-action for emergency cancellation (Mark Out of Stock).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/alpha_theme.dart';

/// Order model for the feed
class PendingOrder {
  final String txId;
  final String recipientName;
  final String productName;
  final double amountZmw;
  final DateTime createdAt;
  final String collectionToken;
  
  PendingOrder({
    required this.txId,
    required this.recipientName,
    required this.productName,
    required this.amountZmw,
    required this.createdAt,
    required this.collectionToken,
  });
  
  factory PendingOrder.fromJson(Map<String, dynamic> json) {
    return PendingOrder(
      txId: json['tx_id'] ?? '',
      recipientName: json['recipient_name'] ?? 'Unknown',
      productName: json['product_name'] ?? 'Unknown',
      amountZmw: (json['amount_zmw'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      collectionToken: json['collection_token'] ?? '',
    );
  }
}

/// Live Order Feed showing Status 300 orders
class LiveOrderFeed extends StatelessWidget {
  final List<PendingOrder> orders;
  final bool isLoading;
  final Future<void> Function(String txId)? onMarkOutOfStock;
  
  const LiveOrderFeed({
    super.key,
    required this.orders,
    this.isLoading = false,
    this.onMarkOutOfStock,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildLoadingTile(),
          childCount: 3,
        ),
      );
    }
    
    if (orders.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _OrderTile(
          order: orders[index],
          onMarkOutOfStock: onMarkOutOfStock,
        ),
        childCount: orders.length,
      ),
    );
  }
  
  Widget _buildLoadingTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AlphaTheme.backgroundCard,
          borderRadius: AlphaTheme.cardRadius,
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AlphaTheme.accentBlue.withOpacity(0.5),
            ),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: AlphaTheme.glassCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AlphaTheme.accentBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AlphaTheme.accentBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pending collections',
            style: TextStyle(
              color: AlphaTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Orders ready for pickup will appear here',
            style: TextStyle(
              color: AlphaTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual order tile with swipe actions
class _OrderTile extends StatelessWidget {
  final PendingOrder order;
  final Future<void> Function(String txId)? onMarkOutOfStock;
  
  const _OrderTile({
    required this.order,
    this.onMarkOutOfStock,
  });
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_ZM',
      symbol: 'K',
      decimalDigits: 0,
    );
    
    final timeAgo = _getTimeAgo(order.createdAt);
    
    return Dismissible(
      key: Key(order.txId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showOutOfStockDialog(context);
      },
      onDismissed: (direction) {
        onMarkOutOfStock?.call(order.txId);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AlphaTheme.accentRed,
          borderRadius: AlphaTheme.cardRadius,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'OUT OF STOCK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: AlphaTheme.glassCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AlphaTheme.accentBlue.withOpacity(0.1),
                  borderRadius: AlphaTheme.buttonRadius,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AlphaTheme.accentBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Order details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(
                        color: AlphaTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AlphaTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'For ${order.recipientName}',
                          style: AlphaTheme.captionText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AlphaTheme.accentAmber.withOpacity(0.2),
                            borderRadius: AlphaTheme.chipRadius,
                          ),
                          child: Text(
                            order.collectionToken,
                            style: const TextStyle(
                              color: AlphaTheme.accentAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: AlphaTheme.captionText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(order.amountZmw),
                    style: const TextStyle(
                      color: AlphaTheme.accentGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_left,
                        size: 12,
                        color: AlphaTheme.textMuted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Swipe',
                        style: TextStyle(
                          color: AlphaTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  Future<bool?> _showOutOfStockDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AlphaTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: AlphaTheme.cardRadius,
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AlphaTheme.accentAmber),
            SizedBox(width: 12),
            Text(
              'Mark Out of Stock?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'This will cancel the order and refund the customer. This action cannot be undone.',
          style: TextStyle(color: AlphaTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: AlphaTheme.dangerButton,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
