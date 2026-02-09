/// =============================================================================
/// KithLy Global Protocol - CUSTOMER HOME (Phase V)
/// home.dart - Customer Dashboard with Re-route Dialog
/// =============================================================================
/// 
/// Project Alpha port of CustomerDashboard.tsx with:
/// - Active orders display
/// - Re-route Dialog (Status 106 listener)
/// - Shop discovery
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/alpha_theme.dart';
import '../../config/feature_flags.dart';

/// Customer Home Dashboard
class CustomerHome extends StatefulWidget {
  final String userId;
  
  const CustomerHome({super.key, required this.userId});
  
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  List<Map<String, dynamic>> _activeOrders = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
    _startStatusPolling();
  }
  
  void _loadActiveOrders() async {
    // TODO: Fetch from API
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _activeOrders = [
        {
          "tx_id": "mock-tx-001",
          "shop_name": "Manda Hill Flowers",
          "product_name": "Birthday Bouquet",
          "status_code": 200,
          "status_text": "Confirmed",
          "amount_zmw": 350.0,
        },
      ];
      _isLoading = false;
    });
  }
  
  void _startStatusPolling() {
    // Poll for status changes every 10 seconds
    // In production, use WebSocket or Firebase Realtime
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkForReroute();
        _startStatusPolling();
      }
    });
  }
  
  void _checkForReroute() {
    // Check if any order has status 106 (ALT_FOUND)
    for (var order in _activeOrders) {
      if (order["status_code"] == 106) {
        _showRerouteDialog(order);
        break;
      }
    }
  }
  
  void _showRerouteDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RerouteDialog(
        order: order,
        onAccept: () {
          Navigator.pop(context);
          _acceptReroute(order["tx_id"]);
        },
        onDecline: () {
          Navigator.pop(context);
          _declineReroute(order["tx_id"]);
        },
      ),
    );
  }
  
  Future<void> _acceptReroute(String txId) async {
    HapticFeedback.heavyImpact();
    // TODO: Call API to accept reroute
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order re-routed successfully!'),
        backgroundColor: AlphaTheme.accentGreen,
      ),
    );
    _loadActiveOrders();
  }
  
  Future<void> _declineReroute(String txId) async {
    // TODO: Call API to decline and refund
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order cancelled. Refund initiated.'),
        backgroundColor: AlphaTheme.accentAmber,
      ),
    );
    _loadActiveOrders();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlphaTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'KithLy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AlphaTheme.primaryOrange,
              ),
            ),
            Text(
              'Send Gifts Anywhere',
              style: TextStyle(
                fontSize: 12,
                color: AlphaTheme.textMuted,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadActiveOrders(),
        color: AlphaTheme.primaryOrange,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildQuickActions(),
                    ),
                  ),
                  
                  // Active Orders Section
                  if (_activeOrders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AlphaTheme.primaryOrange.withOpacity(0.2),
                                borderRadius: AlphaTheme.chipRadius,
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: AlphaTheme.primaryOrange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Active Orders',
                              style: TextStyle(
                                color: AlphaTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _OrderCard(order: _activeOrders[index]),
                          childCount: _activeOrders.length,
                        ),
                      ),
                    ),
                  ],
                  
                  // Discover Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AlphaTheme.secondaryGold.withOpacity(0.2),
                              borderRadius: AlphaTheme.chipRadius,
                            ),
                            child: const Icon(
                              Icons.explore,
                              color: AlphaTheme.secondaryGold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Discover Shops',
                            style: TextStyle(
                              color: AlphaTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Shop categories placeholder
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _CategoryChip(icon: Icons.cake, label: 'Cakes'),
                          _CategoryChip(icon: Icons.local_florist, label: 'Flowers'),
                          _CategoryChip(icon: Icons.card_giftcard, label: 'Gifts'),
                          _CategoryChip(icon: Icons.shopping_bag, label: 'Hampers'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.send,
            label: 'Send Gift',
            color: AlphaTheme.primaryOrange,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            color: AlphaTheme.accentRed,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history,
            label: 'History',
            color: AlphaTheme.accentBlue,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

/// Re-route Dialog - shown when Status 106 detected
class RerouteDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  
  const RerouteDialog({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });
  
  @override
  Widget build(BuildContext context) {
    final originalShop = order["original_shop_name"] ?? "Shop A";
    final alternativeShop = order["alternative_shop_name"] ?? "Shop B";
    final distanceDiff = order["distance_diff"] ?? "+1.2km";
    final priceDiff = order["price_diff"] ?? "K0";
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AlphaReRouteGlass(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AlphaTheme.accentGreen.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AlphaTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Good News! 🟢',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'We found an alternative shop nearby!',
                    style: TextStyle(color: AlphaTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Visual comparison
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AlphaTheme.accentRed.withOpacity(0.1),
                            borderRadius: AlphaTheme.buttonRadius,
                            border: Border.all(color: AlphaTheme.accentRed.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.close, color: AlphaTheme.accentRed),
                              const SizedBox(height: 8),
                              Text(
                                originalShop,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                              const Text('Failed', style: TextStyle(color: AlphaTheme.accentRed, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward, color: AlphaTheme.textMuted),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AlphaTheme.accentGreen.withOpacity(0.1),
                            borderRadius: AlphaTheme.buttonRadius,
                            border: Border.all(color: AlphaTheme.accentGreen.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check, color: AlphaTheme.accentGreen),
                              const SizedBox(height: 8),
                              Text(
                                alternativeShop,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                              Text('($distanceDiff)', style: const TextStyle(color: AlphaTheme.accentGreen, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price impact
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AlphaTheme.backgroundGlass,
                      borderRadius: AlphaTheme.chipRadius,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Price impact: ', style: TextStyle(color: AlphaTheme.textMuted)),
                        Text(
                          priceDiff,
                          style: const TextStyle(
                            color: AlphaTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AlphaTheme.textMuted,
                        side: const BorderSide(color: AlphaTheme.textMuted),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel & Refund'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: AlphaTheme.successButton,
                      child: const Text('Accept ✓'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AlphaTheme.glassCard,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: AlphaTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  
  const _OrderCard({required this.order});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AlphaTheme.glassCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AlphaTheme.primaryOrange.withOpacity(0.2),
                borderRadius: AlphaTheme.chipRadius,
              ),
              child: const Icon(Icons.card_giftcard, color: AlphaTheme.primaryOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order["product_name"] ?? "Gift",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    order["shop_name"] ?? "Shop",
                    style: AlphaTheme.captionText,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'K${order["amount_zmw"]}',
                  style: const TextStyle(color: AlphaTheme.accentGreen, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentBlue.withOpacity(0.2),
                    borderRadius: AlphaTheme.chipRadius,
                  ),
                  child: Text(
                    order["status_text"] ?? "Pending",
                    style: const TextStyle(color: AlphaTheme.accentBlue, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _CategoryChip({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AlphaTheme.glassCard,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AlphaTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
