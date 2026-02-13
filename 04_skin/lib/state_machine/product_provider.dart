/// =============================================================================
/// KithLy Global Protocol - PRODUCT PROVIDER (Phase IV-Extension)
/// product_provider.dart - Single Source of Truth for Products
/// =============================================================================
///
/// The "Live Mirror" brain: merchant edits here instantly reflect in the
/// customer catalog through Provider's notifyListeners().
library;

import 'package:flutter/foundation.dart';

/// Product model shared between merchant and customer views
class ProductModel {
  final String skuId;
  String shopId;
  String shopName;
  String shopCity;
  String name;
  double priceZmw;
  int stockLevel;
  String? imageUrl;
  String category;
  String description;
  bool isHidden;

  ProductModel({
    required this.skuId,
    required this.shopId,
    this.shopName = '',
    this.shopCity = '',
    required this.name,
    required this.priceZmw,
    this.stockLevel = 0,
    this.imageUrl,
    this.category = 'General',
    this.description = '',
    this.isHidden = false,
  });

  /// Whether this product is visible to customers
  bool get isAvailable => !isHidden && stockLevel > 0;

  /// Stock percentage for urgency protocol
  int get stockPercent => stockLevel.clamp(0, 100);

  /// Copy with overrides
  ProductModel copyWith({
    String? name,
    double? priceZmw,
    int? stockLevel,
    String? imageUrl,
    String? category,
    String? description,
    bool? isHidden,
    String? shopId,
    String? shopName,
    String? shopCity,
  }) {
    return ProductModel(
      skuId: skuId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopCity: shopCity ?? this.shopCity,
      name: name ?? this.name,
      priceZmw: priceZmw ?? this.priceZmw,
      stockLevel: stockLevel ?? this.stockLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      description: description ?? this.description,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

/// Product Provider — the Global Brain
class ProductProvider extends ChangeNotifier {
  final List<ProductModel> _products = [];

  ProductProvider() {
    _initMockProducts();
  }

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// All products (merchant view — includes hidden/out-of-stock)
  List<ProductModel> get allProducts => List.unmodifiable(_products);

  /// Available products (customer view — excludes hidden/out-of-stock)
  List<ProductModel> get availableProducts =>
      _products.where((p) => p.isAvailable).toList();

  /// Find a product by SKU
  ProductModel? getProduct(String skuId) {
    try {
      return _products.firstWhere((p) => p.skuId == skuId);
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // CRUD
  // ===========================================================================

  /// Add a new product
  void addProduct(ProductModel product) {
    _products.add(product);
    notifyListeners();
  }

  /// Update an existing product by SKU
  bool updateProduct(ProductModel updated) {
    final idx = _products.indexWhere((p) => p.skuId == updated.skuId);
    if (idx == -1) return false;

    _products[idx] = updated;
    notifyListeners();
    return true;
  }

  /// Delete a product by SKU
  bool deleteProduct(String skuId) {
    _products.removeWhere((p) => p.skuId == skuId);
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // MOCK DATA (matches sender_catalog.dart originals)
  // ===========================================================================

  void _initMockProducts() {
    _products.addAll([
      ProductModel(
        skuId: 'SKU-SHOP-001',
        shopId: 'shop-1',
        shopName: 'Shoprite Manda Hill',
        shopCity: 'Lusaka',
        name: 'Coca-Cola 2L',
        priceZmw: 45.00,
        stockLevel: 150,
        category: 'Beverages',
        description: 'Refreshing 2-litre Coca-Cola bottle.',
      ),
      ProductModel(
        skuId: 'SKU-SHOP-002',
        shopId: 'shop-1',
        shopName: 'Shoprite Manda Hill',
        shopCity: 'Lusaka',
        name: 'White Bread Loaf',
        priceZmw: 32.00,
        stockLevel: 80,
        category: 'Bakery',
        description: 'Fresh white bread, baked daily.',
      ),
      ProductModel(
        skuId: 'SKU-HW-001',
        shopId: 'shop-2',
        shopName: 'Chilenje Hardware',
        shopCity: 'Lusaka',
        name: 'Hammer 500g',
        priceZmw: 85.00,
        stockLevel: 25,
        category: 'Tools',
        description: 'Heavy-duty 500g claw hammer.',
      ),
      ProductModel(
        skuId: 'SKU-PHARM-001',
        shopId: 'shop-3',
        shopName: 'Rhodes Park Pharmacy',
        shopCity: 'Lusaka',
        name: 'Paracetamol 500mg',
        priceZmw: 28.00,
        stockLevel: 200,
        category: 'Medicine',
        description: 'Pain relief tablets, pack of 20.',
      ),
      ProductModel(
        skuId: 'SKU-GROC-001',
        shopId: 'shop-1',
        shopName: 'Shoprite Manda Hill',
        shopCity: 'Lusaka',
        name: '5kg Mealie Meal',
        priceZmw: 120.00,
        stockLevel: 60,
        category: 'Groceries',
        description: 'Zambian staple, finely ground white maize.',
      ),
    ]);
  }
}
