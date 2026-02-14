import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/customer/active_order_card.dart';
import '../../widgets/customer/order_history_tile.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KithLyColors.darkBackground,
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KithLyColors.orange.withOpacity(0.1),
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // 1. Identity Layer (AppBar)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Good Morning,",
                              style: AlphaTheme.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text("Andy", style: AlphaTheme.headlineMedium),
                          ],
                        ),
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: KithLyColors.alert,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Hero Layer (Active Orders)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Orders (2)",
                          style: AlphaTheme.labelLarge.copyWith(
                            color: KithLyColors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ActiveOrderCard(
                          shopName: "Urban Coffee",
                          items: "2x Latte, 1x Croissant",
                          price: "K 145.00",
                          pickupCode: "KLY-8821",
                          onViewReceipt: () {},
                        ),
                        ActiveOrderCard(
                          shopName: "Tech Haven",
                          items: "1x USB-C Hub",
                          price: "K 450.00",
                          pickupCode: "KLY-9942",
                          onViewReceipt: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Archive Layer (History)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recent History",
                          style: AlphaTheme.labelLarge.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return OrderHistoryTile(
                        shopName: "Shop #${index + 1}",
                        date: "Feb ${14 - index}, 2026",
                        price: "K ${100 + index * 50}",
                        status: index == 0 ? "DELIVERED" : "CANCELLED",
                        onTap: () {},
                      );
                    }, childCount: 5),
                  ),
                ),

                // Bottom Padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      // Bottom Nav (Mock)
      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.all(24),
        decoration: GlassStyles.basic.copyWith(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: KithLyColors.orange),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white38),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white38),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
