/// =============================================================================
/// KithLy Global Protocol - SHOP COMMAND CENTER (Phase IV-Extension)
/// shop_portal.dart - Main Shop Dashboard
/// =============================================================================
///
/// The Shop Command Center with Revenue HUD, prominent Scan button (THE TRIGGER),
/// Live Order Feed, and Conditional Urgency Inventory Protocol.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/alpha_theme.dart';
import '../../config/feature_flags.dart';
import '../../state_machine/dashboard_provider.dart';
import 'revenue_card.dart';
import 'live_order_feed.dart';
import 'qr_scanner_screen.dart';
import 'delivery_dispatch_card.dart';

/// Shop Command Center - Main dashboard for shop owners
class ShopPortal extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopPortal({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopPortal> createState() => _ShopPortalState();
}

class _ShopPortalState extends State<ShopPortal> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// Urgency Protocol: 1-second heartbeat to check for expired orders
  Timer? _urgencyTimer;

  /// Revenue pulse: brief scale-up when revenue changes
  late AnimationController _revenuePulseController;
  late Animation<double> _revenuePulseAnimation;
  double _previousRevenue = 0.0;

  @override
  void initState() {
    super.initState();

    // Pulsing animation for Scan button - draws attention
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Revenue pulse animation
    _revenuePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _revenuePulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _revenuePulseController,
        curve: Curves.easeOut,
      ),
    );

    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard(widget.shopId);
    });

    // === Urgency Protocol: Start 1s heartbeat ===
    _urgencyTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkUrgentOrderTimeouts(),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revenuePulseController.dispose();
    _urgencyTimer?.cancel();
    super.dispose();
  }

  /// Check all urgent orders for timeout (120s expired)
  void _checkUrgentOrderTimeouts() {
    final dashboard = context.read<DashboardProvider>();
    final now = DateTime.now();

    final expiredOrders = dashboard.pendingOrders
        .where((o) =>
            o.isUrgent && o.expiresAt != null && now.isAfter(o.expiresAt!))
        .toList();

    for (final order in expiredOrders) {
      // Auto-decline with inventory_timeout reason
      dashboard.declineRequest(order.txId, 'inventory_timeout');

      // Shop Health Score accountability log
      debugPrint(
        '⚠ SHOP HEALTH SCORE -5: order ${order.txId} timed out '
        '(inventory_timeout) — product: ${order.productName}',
      );
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          shopId: widget.shopId,
          txId: 'test_tx', // Default txId injection
          onVerified: (result) {
            // Refresh dashboard after successful verification
            context.read<DashboardProvider>().loadDashboard(widget.shopId);
            _showSuccessSnackbar(result);
          },
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AlphaTheme.accentGreen),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AlphaTheme.backgroundCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_ZM',
      symbol: 'K',
      decimalDigits: 0,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Scaffold(
          backgroundColor: AlphaTheme.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Consumer<DashboardProvider>(
              builder: (context, dashboard, _) {
                return Column(
                  children: [
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Command Center',
                          style: TextStyle(
                            fontSize: 12,
                            color: AlphaTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live Revenue Today chip — with pulse animation
                        Builder(
                          builder: (context) {
                            // Detect revenue change and trigger pulse
                            if (dashboard.liveRevenueToday !=
                                    _previousRevenue &&
                                _previousRevenue > 0) {
                              _revenuePulseController.forward().then(
                                    (_) => _revenuePulseController.reverse(),
                                  );
                            }
                            _previousRevenue = dashboard.liveRevenueToday;

                            return ScaleTransition(
                              scale: _revenuePulseAnimation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AlphaTheme.accentGreen.withOpacity(0.15),
                                  borderRadius: AlphaTheme.chipRadius,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AlphaTheme.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currencyFormat.format(
                                        dashboard.liveRevenueToday,
                                      ),
                                      style: const TextStyle(
                                        color: AlphaTheme.accentGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  // TODO: Navigate to settings
                },
              ),
            ],
          ),
          body: Consumer<DashboardProvider>(
            builder: (context, dashboard, child) {
              return RefreshIndicator(
                onRefresh: () => dashboard.loadDashboard(widget.shopId),
                color: AlphaTheme.accentGreen,
                backgroundColor: AlphaTheme.backgroundCard,
                child: CustomScrollView(
                  slivers: [
                    // Revenue HUD
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: RevenueCard(
                          todayRevenue: dashboard.todayRevenue,
                          weeklyData: dashboard.weeklyRevenue,
                          isLoading: dashboard.isLoading,
                        ),
                      ),
                    ),

                    // === Low-Stock Warning Banner ===
                    if (dashboard.hasUrgentOrders)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AlphaTheme.urgentBannerDecoration,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AlphaTheme.accentAmber,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '⚠️ Low stock detected. Orders for items below 50% '
                                    'require 2-minute verification to prevent re-routing.',
                                    style: TextStyle(
                                      color: AlphaTheme.accentAmber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Section Title: Ready for Collection
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AlphaTheme.accentAmber.withOpacity(0.2),
                                borderRadius: AlphaTheme.chipRadius,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AlphaTheme.accentAmber,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Ready for Collection',
                              style: TextStyle(
                                color: AlphaTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AlphaTheme.accentAmber.withOpacity(0.2),
                                borderRadius: AlphaTheme.chipRadius,
                              ),
                              child: Text(
                                '${dashboard.pendingOrders.length}',
                                style: const TextStyle(
                                  color: AlphaTheme.accentAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Live Order Feed
                    LiveOrderFeed(
                      orders: dashboard.pendingOrders,
                      isLoading: dashboard.isLoading,
                      onMarkOutOfStock: (txId) async {
                        await dashboard.cancelOrder(txId, 'out_of_stock');
                      },
                    ),

                    // The "Sleeper" Delivery Bridge - Hidden by Feature Flag
                    if (FeatureFlags.enableManualDelivery &&
                        dashboard.pendingOrders.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AlphaTheme.accentBlue
                                          .withOpacity(0.2),
                                      borderRadius: AlphaTheme.chipRadius,
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping,
                                      color: AlphaTheme.accentBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Dispatch Deliveries',
                                    style: TextStyle(
                                      color: AlphaTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Delivery cards for each pending order
                              ...dashboard.pendingOrders.map(
                                (order) => DeliveryDispatchCard(
                                  txId: order.txId,
                                  recipientName: order.recipientName,
                                  productName: order.productName,
                                  onDispatched: () {
                                    dashboard.loadDashboard(widget.shopId);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bottom padding for FAB
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              );
            },
          ),

          // THE TRIGGER - Prominent Scan Button
          floatingActionButton: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: AlphaTheme.scanButtonDecoration,
                  child: FloatingActionButton(
                    onPressed: _openScanner,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    highlightElevation: 0,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SCAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }
}
