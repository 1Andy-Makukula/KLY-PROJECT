/// =============================================================================
/// KithLy Global Protocol - PRODUCT REPOSITORY (Phase 1)
/// product_repository.dart - Stale-While-Revalidate Caching Layer
/// =============================================================================
///
/// Repository Pattern: serves cached data instantly for snappy UI,
/// then silently revalidates from ApiService in the background.
/// If the API fails, the cached data remains — no crashes.
library;

import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Product Repository — Stale-While-Revalidate Cache
///
/// Usage:
/// ```dart
/// final repo = ProductRepository();
/// // Listen for updates
/// repo.productsNotifier.addListener(() {
///   final products = repo.productsNotifier.value;
///   // rebuild UI
/// });
/// // Kick off fetch (returns cached immediately, revalidates in background)
/// repo.getProducts('shop-1');
/// ```
class ProductRepository {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  // ---------------------------------------------------------------------------
  // IN-MEMORY CACHE
  // ---------------------------------------------------------------------------

  /// Static RAM cache keyed by shopId.
  /// Each entry holds the raw product list from the API.
  static final Map<String, List<Map<String, dynamic>>> _memoryCache = {};

  // ---------------------------------------------------------------------------
  // CHANGE NOTIFICATION
  // ---------------------------------------------------------------------------

  /// The UI listens to this notifier. Its value is updated whenever
  /// fresh data arrives (or when cached data is served on first call).
  final ValueNotifier<List<Map<String, dynamic>>> productsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// `true` while a background revalidation is in-flight.
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Holds the last error message (if any). Null means no error.
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  // ---------------------------------------------------------------------------
  // API BRIDGE
  // ---------------------------------------------------------------------------

  final ApiService _api = ApiService();

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  /// Fetch products for [shopId] using Stale-While-Revalidate:
  ///
  /// 1. **Stale** — If cached data exists, push it into [productsNotifier]
  ///    immediately so the UI can render without waiting.
  /// 2. **Revalidate** — Fire a background call to [ApiService.getShopProducts]
  ///    to fetch the freshest data from the gateway.
  /// 3. **Update** — If the fresh data differs from the cache, update both
  ///    [_memoryCache] and [productsNotifier] so the UI rebuilds.
  /// 4. **Error Safety** — If the API call fails, the cached data stays
  ///    in the notifier. The UI never sees a blank screen.
  ///
  /// Returns the currently cached list (may be empty on first cold call).
  List<Map<String, dynamic>> getProducts(String shopId) {
    // ── Step 1: Serve stale data instantly ──────────────────────────────
    final cached = _memoryCache[shopId];
    if (cached != null) {
      productsNotifier.value = List.unmodifiable(cached);
    }

    // ── Step 2: Background revalidation ─────────────────────────────────
    _revalidate(shopId);

    // Return whatever we have right now (instant for the caller)
    return cached ?? [];
  }

  /// Force a fresh fetch, ignoring the cache.
  /// Useful after the merchant adds/edits a product locally.
  Future<void> forceRefresh(String shopId) async {
    await _revalidate(shopId);
  }

  /// Clear the entire cache (e.g. on logout).
  void clearCache() {
    _memoryCache.clear();
    productsNotifier.value = [];
    error.value = null;
  }

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  /// Calls the API and updates cache + notifier if data changed.
  Future<void> _revalidate(String shopId) async {
    isLoading.value = true;
    error.value = null;

    try {
      final freshRaw = await _api.getShopProducts(shopId);

      // Cast each item to Map<String, dynamic>
      final List<Map<String, dynamic>> freshData = freshRaw
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      // ── Step 3: Update only if data actually changed ──────────────────
      final oldData = _memoryCache[shopId];
      if (!_listEquals(oldData, freshData)) {
        _memoryCache[shopId] = freshData;
        productsNotifier.value = List.unmodifiable(freshData);
      }
    } catch (e) {
      // ── Step 4: Graceful error — keep cached data intact ──────────────
      error.value = e.toString();
      debugPrint('[ProductRepository] Revalidation failed for $shopId: $e');
      // productsNotifier is NOT cleared — stale data stays visible
    } finally {
      isLoading.value = false;
    }
  }

  /// Shallow comparison of two lists of maps.
  bool _listEquals(
    List<Map<String, dynamic>>? a,
    List<Map<String, dynamic>>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (!mapEquals(a[i], b[i])) return false;
    }
    return true;
  }
}
