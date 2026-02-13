/// =============================================================================
/// KithLy Global Protocol - LIVE ORDER FEED (Phase IV-Extension)
/// live_order_feed.dart - Status 300 Orders with Swipe Actions
/// =============================================================================
///
/// Displays orders ready for collection (Status 300).
/// Swipe-to-action for emergency cancellation (Mark Out of Stock).
library;

import 'dart:async';
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

  /// Status codes: 300 = READY, 400 = COLLECTED
  int status;
  DateTime? collectedAt;

  /// Urgency fields — set by DashboardProvider when stock ≤50%
  bool isUrgent;
  DateTime? expiresAt;
  final int? stockPercent;

  PendingOrder({
    required this.txId,
    required this.recipientName,
    required this.productName,
    required this.amountZmw,
    required this.createdAt,
    required this.collectionToken,
    this.status = 300,
    this.collectedAt,
    this.isUrgent = false,
    this.expiresAt,
    this.stockPercent,
  });

  /// Whether this order has been collected (status 400)
  bool get isCollected => status >= 400;

  factory PendingOrder.fromJson(Map<String, dynamic> json) {
    return PendingOrder(
      txId: json['tx_id'] ?? '',
      recipientName: json['recipient_name'] ?? 'Unknown',
      productName: json['product_name'] ?? 'Unknown',
      amountZmw: (json['amount_zmw'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      collectionToken: json['collection_token'] ?? '',
      status: json['status'] as int? ?? 300,
      collectedAt: json['collected_at'] != null
          ? DateTime.tryParse(json['collected_at'])
          : null,
      stockPercent: json['stock_percent'] as int?,
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

/// Individual order tile with swipe actions and urgency support
class _OrderTile extends StatefulWidget {
  final PendingOrder order;
  final Future<void> Function(String txId)? onMarkOutOfStock;

  const _OrderTile({
    required this.order,
    this.onMarkOutOfStock,
  });

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for urgent cards
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupUrgencyTimer();
  }

  @override
  void didUpdateWidget(covariant _OrderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.isUrgent != oldWidget.order.isUrgent ||
        widget.order.expiresAt != oldWidget.order.expiresAt) {
      _setupUrgencyTimer();
    }
  }

  void _setupUrgencyTimer() {
    _countdownTimer?.cancel();

    if (widget.order.isUrgent && widget.order.expiresAt != null) {
      _pulseController.repeat(reverse: true);
      _updateRemaining();
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(),
      );
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _updateRemaining() {
    if (!mounted) return;
    final expires = widget.order.expiresAt;
    if (expires == null) return;

    final diff = expires.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _countdownText {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_ZM',
      symbol: 'K',
      decimalDigits: 0,
    );

    final timeAgo = _getTimeAgo(widget.order.createdAt);
    final isUrgent = widget.order.isUrgent;
    final isCollected = widget.order.isCollected;

    // === Collected Order: show dimmed card with success badge ===
    if (isCollected) {
      final collectedTime = widget.order.collectedAt;
      final collectedLabel = collectedTime != null
          ? DateFormat('HH:mm').format(collectedTime)
          : 'just now';

      return Opacity(
        opacity: 0.55,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: AlphaTheme.glassCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentGreen.withOpacity(0.15),
                    borderRadius: AlphaTheme.buttonRadius,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AlphaTheme.accentGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.productName,
                        style: const TextStyle(
                          color: AlphaTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AlphaTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For ${widget.order.recipientName}',
                        style: AlphaTheme.captionText,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(widget.order.amountZmw),
                      style: const TextStyle(
                        color: AlphaTheme.accentGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AlphaTheme.accentGreen.withOpacity(0.15),
                        borderRadius: AlphaTheme.chipRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 10,
                            color: AlphaTheme.accentGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Collected • $collectedLabel',
                            style: const TextStyle(
                              color: AlphaTheme.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(widget.order.txId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showOutOfStockDialog(context);
      },
      onDismissed: (direction) {
        widget.onMarkOutOfStock?.call(widget.order.txId);
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
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: isUrgent
                ? AlphaTheme.urgentCardDecoration.copyWith(
                    border: Border.all(
                      color: AlphaTheme.accentRed.withOpacity(
                        0.6 + (_pulseAnimation.value * 0.4),
                      ),
                      width: 2,
                    ),
                  )
                : AlphaTheme.glassCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Product icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? AlphaTheme.accentRed.withOpacity(0.15)
                              : AlphaTheme.accentBlue.withOpacity(0.1),
                          borderRadius: AlphaTheme.buttonRadius,
                        ),
                        child: Icon(
                          isUrgent
                              ? Icons.warning_amber_rounded
                              : Icons.card_giftcard,
                          color: isUrgent
                              ? AlphaTheme.accentRed
                              : AlphaTheme.accentBlue,
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
                              widget.order.productName,
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
                                  'For ${widget.order.recipientName}',
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
                                    color:
                                        AlphaTheme.accentAmber.withOpacity(0.2),
                                    borderRadius: AlphaTheme.chipRadius,
                                  ),
                                  child: Text(
                                    widget.order.collectionToken,
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

                      // Amount + countdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(widget.order.amountZmw),
                            style: const TextStyle(
                              color: AlphaTheme.accentGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isUrgent) ...[
                            // Countdown badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AlphaTheme.accentRed.withOpacity(0.2),
                                borderRadius: AlphaTheme.chipRadius,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    size: 12,
                                    color: AlphaTheme.accentRed,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _countdownText,
                                    style: const TextStyle(
                                      color: AlphaTheme.accentRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
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
                        ],
                      ),
                    ],
                  ),

                  // Urgent merchant wait message
                  if (isUrgent) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AlphaTheme.accentRed.withOpacity(0.08),
                        borderRadius: AlphaTheme.chipRadius,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_bottom,
                            size: 14,
                            color: AlphaTheme.accentAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Customer Wait: Verifying stock ($_countdownText remaining)',
                              style: const TextStyle(
                                color: AlphaTheme.accentAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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
