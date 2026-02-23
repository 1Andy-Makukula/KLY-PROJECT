/// =============================================================================
/// KithLy Global Protocol - SHOP DASHBOARD (Phase V)
/// dashboard.dart - Shop Command Center with Action Grid
/// =============================================================================
///
/// Project Alpha port of ShopPortal.tsx with:
/// - Revenue chart (fl_chart)
/// - Action Grid: Scan Order (Hero), Requests (Baker's Bell), Inventory
/// - Yango Bridge (hidden behind feature flag)
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../theme/alpha_theme.dart';
import '../../config/feature_flags.dart';
import '../../state_machine/dashboard_provider.dart';
import '../shop_portal/qr_scanner_screen.dart';
import '../shop_portal/delivery_dispatch_card.dart';

/// Shop Dashboard - Command Center with Action Grid
class ShopDashboard extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopDashboard({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _bakerRequestCount = 0; // Baker's Protocol pending count

  @override
  void initState() {
    super.initState();

    // Pulsing animation for Hero Scan button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard(widget.shopId);
      _loadBakerRequests();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadBakerRequests() async {
    // TODO: Fetch Status 110 orders (Baker's Protocol)
    setState(() => _bakerRequestCount = 2); // Mock
  }

  void _openScanner({String? txId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          shopId: widget.shopId,
          txId: txId ?? '', // Pass selected txId or empty string
          onVerified: (result) {
            context.read<DashboardProvider>().loadDashboard(widget.shopId);
          },
        ),
      ),
    );
  }

  void _openBakerRequests() {
    // TODO: Navigate to Baker's Protocol requests screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening custom order requests...')),
    );
  }

  void _openInventory() {
    // TODO: Navigate to inventory management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening inventory...')),
    );
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
            Text(
              widget.shopName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Command Center',
              style: TextStyle(fontSize: 12, color: AlphaTheme.textMuted),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          return RefreshIndicator(
            onRefresh: () => dashboard.loadDashboard(widget.shopId),
            color: AlphaTheme.primaryOrange,
            child: CustomScrollView(
              slivers: [
                // Revenue Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _RevenueChart(
                      todayRevenue: dashboard.todayRevenue,
                      weeklyData: dashboard.weeklyRevenue,
                      isLoading: dashboard.isLoading,
                    ),
                  ),
                ),

                // Action Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ActionGrid(
                      onScanTap: () => _openScanner(), // General scan
                      onRequestsTap: _openBakerRequests,
                      onInventoryTap: _openInventory,
                      requestCount: _bakerRequestCount,
                      pulseAnimation: _pulseAnimation,
                    ),
                  ),
                ),

                // Pending Orders Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                              horizontal: 10, vertical: 4),
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

                // Order cards
                if (dashboard.pendingOrders.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = dashboard.pendingOrders[index];
                          return _OrderCard(
                            order: order,
                            onTap: () => _openScanner(
                                txId: order.txId), // Pass txId to scanner
                          );
                        },
                        childCount: dashboard.pendingOrders.length,
                      ),
                    ),
                  ),

                // Yango Bridge (Feature Flag)
                if (FeatureFlags.enableManualDelivery &&
                    dashboard.pendingOrders.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_shipping,
                                  color: AlphaTheme.accentBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Dispatch Delivery',
                                style: TextStyle(
                                    color: AlphaTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DeliveryDispatchCard(
                            txId: dashboard.pendingOrders.first.txId,
                            recipientName:
                                dashboard.pendingOrders.first.recipientName,
                            productName:
                                dashboard.pendingOrders.first.productName,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Revenue Chart using fl_chart
class _RevenueChart extends StatelessWidget {
  final double todayRevenue;
  final List<double> weeklyData;
  final bool isLoading;

  const _RevenueChart({
    required this.todayRevenue,
    required this.weeklyData,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AlphaTheme.glassCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: AlphaTheme.accentGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Revenue',
                style: TextStyle(color: AlphaTheme.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AlphaTheme.accentGreen.withOpacity(0.2),
                  borderRadius: AlphaTheme.chipRadius,
                ),
                child: const Text(
                  'ZRA ✓',
                  style: TextStyle(
                      color: AlphaTheme.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLoading ? '...' : 'K${todayRevenue.toStringAsFixed(0)}',
            style: AlphaTheme.currencyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: isLoading ? _buildLoadingChart() : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
            AlphaTheme.accentGreen.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildChart() {
    final data =
        weeklyData.isEmpty ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] : weeklyData;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY == 0 ? 100 : maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i]),
            ),
            isCurved: true,
            color: AlphaTheme.accentGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: AlphaTheme.revenueGradient,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action Grid with Hero Scan Button
class _ActionGrid extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onInventoryTap;
  final int requestCount;
  final Animation<double> pulseAnimation;

  const _ActionGrid({
    required this.onScanTap,
    required this.onRequestsTap,
    required this.onInventoryTap,
    required this.requestCount,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Requests (Baker's Bell)
        Expanded(
          child: _ActionCard(
            icon: Icons.notifications_active,
            label: 'Requests',
            color: AlphaTheme.secondaryGold,
            badgeCount: requestCount,
            onTap: onRequestsTap,
          ),
        ),
        const SizedBox(width: 12),

        // Scan Order (HERO)
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: pulseAnimation.value,
              child: GestureDetector(
                onTap: onScanTap,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: AlphaTheme.scanButtonDecoration,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          size: 36, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        'SCAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        // Inventory
        Expanded(
          child: _ActionCard(
            icon: Icons.inventory,
            label: 'Inventory',
            color: AlphaTheme.accentBlue,
            onTap: onInventoryTap,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: AlphaTheme.glassCard,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AlphaTheme.glassCard,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AlphaTheme.primaryOrange.withOpacity(0.2),
                borderRadius: AlphaTheme.chipRadius,
              ),
              child: const Icon(Icons.card_giftcard,
                  color: AlphaTheme.primaryOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.recipientName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(order.productName, style: AlphaTheme.captionText),
                ],
              ),
            ),
            Text(
              order.collectionToken,
              style: const TextStyle(
                color: AlphaTheme.accentGreen,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
