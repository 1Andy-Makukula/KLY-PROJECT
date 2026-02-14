import 'package:flutter/material.dart';
import '../../theme/alpha_theme.dart';
import '../glass_card.dart';

class ProductGlassCard extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final String status; // "In Stock", "Low Stock", "Out of Stock"
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductGlassCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.status,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = KithLyColors.emerald;
    if (status == "Low Stock") statusColor = KithLyColors.orange;
    if (status == "Out of Stock") statusColor = KithLyColors.alert;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Area (Placeholder for now if URL is not valid)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    color: Colors.black26,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Details Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AlphaTheme.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            price,
                            style: AlphaTheme.bodyMedium.copyWith(
                              color: KithLyColors.gold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Hover/Edit Overlay (Actually just visible buttons for now as hover logic is complex in simple widget)
          // For simplicity in this iteration, we add an edit button at top right
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (onEdit != null)
                  _ActionButton(
                    icon: Icons.edit,
                    onTap: onEdit!,
                    color: Colors.white,
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete,
                    onTap: onDelete!,
                    color: KithLyColors.alert,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
