import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../../widgets/glass_container.dart';

class ShopCardGlass extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String rating;
  final String deliveryTime;
  final bool isOpen;
  final VoidCallback? onTap;

  const ShopCardGlass({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    required this.isOpen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'shop_hero_$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AlphaTheme.orange.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // If closed, apply greyscale filter concept (handled via opacity/overlay here for simplicity)
              // Logic: If !isOpen, we could wrap the image in ColorFiltered, but for now we'll stick to the layout structure.
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // 1. Background Image
                  Positioned.fill(
                    child: isOpen
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          ),
                  ),

                  // 2. Frost Gradient (Bottom)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 150,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // 3. Glass Overlay (Bottom 30%)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AlphaTheme.labelLarge.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Rating Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AlphaTheme.gold,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating,
                                      style: AlphaTheme.labelLarge.copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Time
                              Text(
                                deliveryTime,
                                style: AlphaTheme.bodyMedium.copyWith(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Status Pulse (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOpen ? AlphaTheme.emerald : AlphaTheme.alert,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isOpen
                                          ? AlphaTheme.emerald
                                          : AlphaTheme.alert)
                                      .withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
