import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shop/score_card.dart';
import '../../widgets/shop/product_glass_card.dart';
import '../../widgets/shop/order_tile.dart';
import '../../widgets/charts/revenue_glass_chart.dart';
import '../../widgets/animations/pulse_icon.dart';
import 'trash_bin_screen.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  int _selectedIndex = 0;
  bool _hasNewOrders = true; // Mock state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KithLyColors.darkBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 800;

          return Row(
            children: [
              if (isDesktop) _buildDesktopSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    // Main Content with Fade Transition
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: isDesktop ? 0 : 100,
                      ), // Space for mobile dock
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selectedIndex),
                          child: _buildCurrentView(isDesktop),
                        ),
                      ),
                    ),

                    // Mobile Floating Dock
                    if (!isDesktop)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: _buildMobileDock(),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentView(bool isDesktop) {
    switch (_selectedIndex) {
      case 0:
        return _buildAnalysisView(isDesktop);
      case 1:
        return _buildProductsView(isDesktop);
      case 3:
        return _buildOrdersView(isDesktop);
      case 4:
        return const Center(
          child: Text("Settings", style: TextStyle(color: Colors.white)),
        );
      default:
        return const Center(
          child: Text("Scan", style: TextStyle(color: Colors.white)),
        );
    }
  }

  Widget _buildAnalysisView(bool isDesktop) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text("Overview", style: AlphaTheme.headlineMedium),
        const SizedBox(height: 20),

        // Cockpit Layout
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildScoreSection()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildWalletSection()),
            ],
          )
        else
          Column(
            children: [
              _buildScoreSection(),
              const SizedBox(height: 24),
              _buildWalletSection(),
            ],
          ),

        const SizedBox(height: 32),
        const RevenueGlassChart(), // <--- The new component!

        const SizedBox(height: 32),
        Text(
          "Live Metrics",
          style: AlphaTheme.headlineMedium.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        _buildMetricsGrid(isDesktop),
      ],
    );
  }

  Widget _buildScoreSection() {
    return const SizedBox(
      height: 200,
      child: ScoreCard(
        score: 95,
        label: "Excellent",
        trend: "+5 points from last week",
      ),
    );
  }

  Widget _buildWalletSection() {
    return Column(
      children: [
        _buildWalletCard(
          "Available Payout",
          "K 4,500.00",
          KithLyColors.emerald,
          Icons.account_balance_wallet,
        ),
        const SizedBox(height: 16),
        _buildWalletCard(
          "Pending Collection",
          "K 1,250.00",
          KithLyColors.orange,
          Icons.pending_actions,
        ),
      ],
    );
  }

  Widget _buildWalletCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AlphaTheme.bodyMedium),
              Text(
                amount,
                style: AlphaTheme.headlineMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: const [
        _MetricTile(
          icon: Icons.visibility,
          label: "Views",
          value: "1.2k",
          trend: "+12%",
          color: Colors.blue,
        ),
        _MetricTile(
          icon: Icons.shopping_bag,
          label: "Orders",
          value: "48",
          trend: "+5%",
          color: KithLyColors.orange,
        ),
        _MetricTile(
          icon: Icons.star,
          label: "Rating",
          value: "4.8",
          trend: "+0.1",
          color: KithLyColors.gold,
        ),
        _MetricTile(
          icon: Icons.attach_money,
          label: "Revenue",
          value: "5.7k",
          trend: "+15%",
          color: KithLyColors.emerald,
        ),
      ],
    );
  }

  Widget _buildProductsView(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Products", style: AlphaTheme.headlineMedium),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                    ),
                    tooltip: "Ghost Zone",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrashBinScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text("Add New"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KithLyColors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return ProductGlassCard(
                  title: "Product Item #$index",
                  price: "K ${150 + index * 10}",
                  imageUrl: "https://via.placeholder.com/200",
                  status: index % 3 == 0
                      ? "In Stock"
                      : (index % 3 == 1 ? "Low Stock" : "Out of Stock"),
                  onEdit: () {},
                  onDelete: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersView(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Orders", style: AlphaTheme.headlineMedium),
              if (_hasNewOrders) ...[
                const SizedBox(width: 8),
                const PulseIcon(
                  icon: Icons.notifications_active,
                  color: KithLyColors.orange,
                  animate: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Tabs
          Row(
            children: [
              _buildTab("New Orders", true),
              const SizedBox(width: 24),
              _buildTab("History", false),
            ],
          ),
          const SizedBox(height: 24),

          // List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return OrderTile(
                orderId: "#ORD-2026-${1000 + index}",
                customerName: "Customer $index",
                items: "${index + 1}x Item A, ${index}x Item B",
                status: index == 0
                    ? "PAID"
                    : (index == 1 ? "DISPATCH" : "COLLECTED"),
                avatarUrl: "https://via.placeholder.com/50",
                onAction: () {},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Column(
      children: [
        Text(
          label,
          style: isActive
              ? AlphaTheme.labelLarge.copyWith(
                  color: KithLyColors.orange,
                  fontSize: 16,
                )
              : AlphaTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(height: 2, width: 40, color: KithLyColors.orange),
      ],
    );
  }

  // Sidebar Build Methods
  Widget _buildDesktopSidebar() {
    return Container(
      width: 250,
      decoration: GlassStyles.basic,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text("KithLy", style: AlphaTheme.headlineMedium),
          const SizedBox(height: 50),
          _buildSidebarItem(Icons.analytics, "Analysis", 0),
          _buildSidebarItem(Icons.inventory_2, "Products", 1),
          _buildSidebarItem(
            Icons.receipt_long,
            "Orders",
            3,
            hasPulse: _hasNewOrders,
          ),
          _buildSidebarItem(Icons.qr_code_scanner, "Scan", 2),
          _buildSidebarItem(Icons.settings, "Settings", 4),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label,
    int index, {
    bool hasPulse = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: isSelected ? GlassStyles.active : null,
        child: Row(
          children: [
            if (hasPulse)
              PulseIcon(
                icon: icon,
                color: isSelected ? KithLyColors.orange : Colors.white70,
              )
            else
              Icon(
                icon,
                color: isSelected ? KithLyColors.orange : Colors.white70,
              ),
            const SizedBox(width: 16),
            Text(
              label,
              style: isSelected
                  ? AlphaTheme.labelLarge.copyWith(color: KithLyColors.orange)
                  : AlphaTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDock() {
    return Container(
      height: 80,
      decoration: GlassStyles.basic.copyWith(
        borderRadius: BorderRadius.circular(40),
        color: Colors.black.withOpacity(0.6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMobileIcon(Icons.analytics, 0),
          _buildMobileIcon(Icons.inventory_2, 1),
          _buildScanButton(),
          _buildMobileIcon(Icons.receipt_long, 3, hasPulse: _hasNewOrders),
          _buildMobileIcon(Icons.settings, 4),
        ],
      ),
    );
  }

  Widget _buildMobileIcon(IconData icon, int index, {bool hasPulse = false}) {
    final bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: hasPulse
          ? PulseIcon(
              icon: icon,
              color: isSelected ? KithLyColors.orange : Colors.white70,
              animate: true,
            )
          : Icon(
              icon,
              color: isSelected ? KithLyColors.orange : Colors.white70,
              size: 28,
            ),
      onPressed: () => _onItemTapped(index),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [KithLyColors.orange, KithLyColors.gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: KithLyColors.orange.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AlphaTheme.headlineMedium.copyWith(fontSize: 20),
              ),
              Text(label, style: AlphaTheme.bodyMedium.copyWith(fontSize: 12)),
            ],
          ),
          Text(
            trend,
            style: TextStyle(color: KithLyColors.emerald, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
