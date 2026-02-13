/// =============================================================================
/// KithLy Global Protocol - PRODUCT MANAGEMENT SCREEN (Phase IV-Extension)
/// product_management_screen.dart - Merchant Product CRUD Interface
/// =============================================================================
///
/// The "Merchant Control" — displays all products using AlphaTheme glass cards
/// with Edit/Delete actions. FAB opens the edit sheet for adding new products.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/alpha_theme.dart';
import '../../state_machine/product_provider.dart';
import 'edit_product_sheet.dart';

/// Product Management Screen for Shop Portal
class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlphaTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Add, edit, or remove products',
              style: TextStyle(fontSize: 12, color: AlphaTheme.textMuted),
            ),
          ],
        ),
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final count = provider.allProducts.length;
              final available = provider.availableProducts.length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AlphaTheme.accentBlue.withOpacity(0.15),
                      borderRadius: AlphaTheme.chipRadius,
                    ),
                    child: Text(
                      '$available / $count live',
                      style: const TextStyle(
                        color: AlphaTheme.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final products = provider.allProducts;

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AlphaTheme.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products yet',
                    style: TextStyle(
                      color: AlphaTheme.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first product',
                    style: TextStyle(
                      color: AlphaTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _ProductTile(product: products[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AlphaTheme.accentGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProductSheet(),
    );
  }
}

// =============================================================================
// PRODUCT TILE
// =============================================================================

class _ProductTile extends StatelessWidget {
  final ProductModel product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final isUnavailable = !product.isAvailable;

    return Opacity(
      opacity: isUnavailable ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                  color: AlphaTheme.accentBlue.withOpacity(0.12),
                  borderRadius: AlphaTheme.buttonRadius,
                ),
                child: Icon(
                  _getCategoryIcon(product.category),
                  color: AlphaTheme.accentBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + hidden badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              color: AlphaTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isHidden) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AlphaTheme.accentAmber.withOpacity(0.15),
                              borderRadius: AlphaTheme.chipRadius,
                            ),
                            child: const Text(
                              'Hidden',
                              style: TextStyle(
                                color: AlphaTheme.accentAmber,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price + stock + category
                    Row(
                      children: [
                        Text(
                          'K${product.priceZmw.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AlphaTheme.accentGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StockBadge(level: product.stockLevel),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AlphaTheme.backgroundGlass,
                            borderRadius: AlphaTheme.chipRadius,
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: AlphaTheme.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  // Edit
                  IconButton(
                    onPressed: () => _openEditSheet(context),
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AlphaTheme.accentBlue,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit',
                  ),
                  // Delete
                  IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AlphaTheme.accentRed,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProductSheet(product: product),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AlphaTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: AlphaTheme.cardRadius),
        title: const Text(
          'Delete Product',
          style: TextStyle(color: AlphaTheme.textPrimary),
        ),
        content: Text(
          'Remove "${product.name}" permanently?',
          style: const TextStyle(color: AlphaTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.skuId);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AlphaTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'beverages' => Icons.local_drink_rounded,
      'bakery' => Icons.bakery_dining_rounded,
      'tools' => Icons.build_rounded,
      'medicine' => Icons.medical_services_rounded,
      'groceries' => Icons.shopping_basket_rounded,
      'electronics' => Icons.devices_rounded,
      'clothing' => Icons.checkroom_rounded,
      _ => Icons.inventory_2_outlined,
    };
  }
}

// =============================================================================
// STOCK BADGE
// =============================================================================

class _StockBadge extends StatelessWidget {
  final int level;

  const _StockBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (level <= 0) {
      color = AlphaTheme.accentRed;
    } else if (level <= 50) {
      color = AlphaTheme.accentAmber;
    } else {
      color = AlphaTheme.accentGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AlphaTheme.chipRadius,
      ),
      child: Text(
        level <= 0 ? 'Out' : '$level in stock',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
