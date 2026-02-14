import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/customer/promo_slider.dart';
import '../../widgets/customer/featured_shops.dart';
import '../../widgets/customer/feed_filters.dart';
import '../../widgets/shop/product_glass_card.dart'; // Reusing for shop/product items

class LiveFeed extends StatefulWidget {
  const LiveFeed({super.key});

  @override
  State<LiveFeed> createState() => _LiveFeedState();
}

class _LiveFeedState extends State<LiveFeed> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 1. Search & Location Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: GlassStyles.basic.copyWith(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white54),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search for shops or items...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: GlassStyles.basic.copyWith(
                    borderRadius: BorderRadius.circular(16),
                    color: KithLyColors.orange.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: KithLyColors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Promo Slider
        const SliverToBoxAdapter(child: PromoSlider()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // 3. Featured Shops Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Featured Shops",
                  style: AlphaTheme.headlineMedium.copyWith(fontSize: 20),
                ),
                Text(
                  "See All",
                  style: AlphaTheme.bodyMedium.copyWith(
                    color: KithLyColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // 4. Featured Shops List
        const SliverToBoxAdapter(child: FeaturedShops()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // 5. Sticky Filters
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyFilterDelegate(child: const FeedFilters()),
        ),

        // 6. Feed Grid
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return ProductGlassCard(
                title: "Shop Item #$index",
                price: "K ${50 + index * 10}",
                imageUrl: "https://via.placeholder.com/150",
                status: "Open Now",
                onEdit: null, // Read-only for customer
                onDelete: null,
              );
            }, childCount: 10),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: KithLyColors
          .darkBackground, // Opaque background to hide scrolling content behind
      child: child,
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return false;
  }
}
