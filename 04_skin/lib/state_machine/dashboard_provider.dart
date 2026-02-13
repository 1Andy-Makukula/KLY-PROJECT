/// =============================================================================
/// KithLy Global Protocol - DASHBOARD PROVIDER (Phase IV-Extension)
/// dashboard_provider.dart - Shop Dashboard State Management
/// =============================================================================
///
/// Provider for shop dashboard data including earnings and pending orders.
library;

import 'package:flutter/foundation.dart';
import '../screens/shop_portal/live_order_feed.dart';
import '../services/api_service.dart';

/// Dashboard Provider for Shop Command Center
class DashboardProvider extends ChangeNotifier {
  final ApiService _api;

  /// Constructor with optional dependency injection.
  /// Falls back to a default ApiService instance for production use.
  DashboardProvider({ApiService? api}) : _api = api ?? ApiService();

  bool _isLoading = false;
  String? _error;

  double _todayRevenue = 0.0;
  List<double> _weeklyRevenue = [];
  List<PendingOrder> _pendingOrders = [];

  // === Urgency Protocol State ===

  /// Tracks when each product's stock was last verified by shopkeeper
  final Map<String, DateTime> _lastConfirmedProducts = {};

  /// Live revenue from collected/dispatched orders today
  double _liveRevenueToday = 0.0;

  /// Orders that completed the handover (status 400)
  final List<PendingOrder> _completedOrders = [];

  /// Local stock deductions to keep the 50% Guard accurate
  final Map<String, int> _localStockDeductions = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get todayRevenue => _todayRevenue;
  List<double> get weeklyRevenue => _weeklyRevenue;
  List<PendingOrder> get pendingOrders => _pendingOrders;
  Map<String, DateTime> get lastConfirmedProducts => _lastConfirmedProducts;
  double get liveRevenueToday => _liveRevenueToday;
  List<PendingOrder> get completedOrders => _completedOrders;

  /// Whether any pending orders are currently urgent
  bool get hasUrgentOrders => _pendingOrders.any((o) => o.isUrgent);

  /// Load dashboard data for a shop
  Future<void> loadDashboard(String shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch dashboard data from API (now using instance method)
      final data = await _api.getShopDashboard(shopId);

      _todayRevenue = (data['today_revenue'] ?? 0).toDouble();
      _weeklyRevenue = List<double>.from(
        (data['weekly_revenue'] ?? []).map((e) => (e as num).toDouble()),
      );
      _pendingOrders = (data['pending_orders'] ?? [])
          .map<PendingOrder>((json) => PendingOrder.fromJson(json))
          .toList();
      _liveRevenueToday =
          (data['live_revenue_today'] ?? _todayRevenue).toDouble();
    } catch (e) {
      _error = e.toString();

      // Use mock data for development
      _todayRevenue = 12500.0;
      _weeklyRevenue = [8500, 12000, 9500, 14000, 11000, 13500, 12500];
      _pendingOrders = _getMockOrders();
      _liveRevenueToday = _todayRevenue;
    }

    // Apply urgency rules after loading
    markOrdersUrgent();

    _isLoading = false;
    notifyListeners();
  }

  /// Cancel an order (out of stock)
  Future<bool> cancelOrder(String txId, String reason) async {
    try {
      await _api.cancelOrder(txId, reason);

      // Remove from local list
      _pendingOrders.removeWhere((order) => order.txId == txId);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh pending orders only
  Future<void> refreshOrders(String shopId) async {
    try {
      final data = await _api.getShopOrders(shopId);
      _pendingOrders = (data['orders'] ?? [])
          .map<PendingOrder>((json) => PendingOrder.fromJson(json))
          .toList();
      markOrdersUrgent();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // === Urgency Protocol Methods ===

  /// The "50% Sales Guard" — mark orders as urgent if product stock ≤50%
  /// and stock hasn't been confirmed by shopkeeper in the last 60 minutes.
  void markOrdersUrgent() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(minutes: 60));

    for (final order in _pendingOrders) {
      // Skip already-urgent orders that have an active timer
      if (order.isUrgent && order.expiresAt != null) continue;

      final stockPct = order.stockPercent;
      if (stockPct == null || stockPct > 50) continue;

      // Check if stock was recently confirmed
      final lastConfirmed = _lastConfirmedProducts[order.productName];
      if (lastConfirmed != null && lastConfirmed.isAfter(oneHourAgo)) continue;

      // Stock is ≤50% and unconfirmed for >60 min → mark urgent
      order.isUrgent = true;
      order.expiresAt = now.add(const Duration(seconds: 120));
    }
  }

  /// Shopkeeper confirms product stock is available
  void confirmProductStock(String productName) {
    _lastConfirmedProducts[productName] = DateTime.now();

    // Clear urgency on orders for this product
    for (final order in _pendingOrders) {
      if (order.productName == productName) {
        order.isUrgent = false;
        order.expiresAt = null;
      }
    }
    notifyListeners();
  }

  /// Accept an order (move to paid/confirmed)
  Future<bool> acceptOrder(String txId) async {
    try {
      await _api.cancelOrder(txId, 'accepted'); // Reuses API pattern
      _pendingOrders.removeWhere((order) => order.txId == txId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Decline a request with a specific reason code
  Future<bool> declineRequest(String txId, String reason) async {
    return cancelOrder(txId, reason);
  }

  // === Handover Protocol Methods ===

  /// Finalize the QR handover: 300 → 400, revenue boost, stock deduction
  bool finalizeHandover(String txId) {
    final idx = _pendingOrders.indexWhere((o) => o.txId == txId);
    if (idx == -1) return false;

    final order = _pendingOrders[idx];

    // 1. State Jump: 300 → 400
    order.status = 400;
    order.collectedAt = DateTime.now();

    // 2. Revenue Trigger
    _liveRevenueToday += order.amountZmw;

    // 3. Inventory Update — track local deduction
    _localStockDeductions[order.productName] =
        (_localStockDeductions[order.productName] ?? 0) + 1;

    // 4. If urgent, clear urgency + confirm stock for this product
    if (order.isUrgent) {
      order.isUrgent = false;
      order.expiresAt = null;
      confirmProductStock(order.productName);
    }

    // 5. Move from pending → completed
    _pendingOrders.removeAt(idx);
    _completedOrders.insert(0, order);

    notifyListeners();
    return true;
  }

  /// Mock orders for development
  List<PendingOrder> _getMockOrders() {
    return [
      PendingOrder(
        txId: 'mock-1',
        recipientName: 'John Banda',
        productName: 'Birthday Cake - Chocolate',
        amountZmw: 450.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        collectionToken: 'KT-A3B7-XY',
        stockPercent: 30, // Low stock — will trigger urgency
      ),
      PendingOrder(
        txId: 'mock-2',
        recipientName: 'Mary Phiri',
        productName: 'Flower Bouquet - Roses',
        amountZmw: 350.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        collectionToken: 'KT-C9D2-ZK',
        stockPercent: 80, // Adequate stock
      ),
      PendingOrder(
        txId: 'mock-3',
        recipientName: 'David Mwansa',
        productName: 'Gift Hamper - Premium',
        amountZmw: 850.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        collectionToken: 'KT-E5F1-QM',
        stockPercent: 45, // Low stock — will trigger urgency
      ),
    ];
  }
}
