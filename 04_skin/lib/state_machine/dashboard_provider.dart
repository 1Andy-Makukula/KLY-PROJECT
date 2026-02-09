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
  bool _isLoading = false;
  String? _error;
  
  double _todayRevenue = 0.0;
  List<double> _weeklyRevenue = [];
  List<PendingOrder> _pendingOrders = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get todayRevenue => _todayRevenue;
  List<double> get weeklyRevenue => _weeklyRevenue;
  List<PendingOrder> get pendingOrders => _pendingOrders;
  
  /// Load dashboard data for a shop
  Future<void> loadDashboard(String shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Fetch dashboard data from API
      final data = await ApiService.getShopDashboard(shopId);
      
      _todayRevenue = (data['today_revenue'] ?? 0).toDouble();
      _weeklyRevenue = List<double>.from(
        (data['weekly_revenue'] ?? []).map((e) => (e as num).toDouble()),
      );
      _pendingOrders = (data['pending_orders'] ?? [])
          .map<PendingOrder>((json) => PendingOrder.fromJson(json))
          .toList();
      
    } catch (e) {
      _error = e.toString();
      
      // Use mock data for development
      _todayRevenue = 12500.0;
      _weeklyRevenue = [8500, 12000, 9500, 14000, 11000, 13500, 12500];
      _pendingOrders = _getMockOrders();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Cancel an order (out of stock)
  Future<bool> cancelOrder(String txId, String reason) async {
    try {
      await ApiService.cancelOrder(txId, reason);
      
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
      final data = await ApiService.getShopOrders(shopId);
      _pendingOrders = (data['orders'] ?? [])
          .map<PendingOrder>((json) => PendingOrder.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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
      ),
      PendingOrder(
        txId: 'mock-2',
        recipientName: 'Mary Phiri',
        productName: 'Flower Bouquet - Roses',
        amountZmw: 350.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        collectionToken: 'KT-C9D2-ZK',
      ),
      PendingOrder(
        txId: 'mock-3',
        recipientName: 'David Mwansa',
        productName: 'Gift Hamper - Premium',
        amountZmw: 850.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        collectionToken: 'KT-E5F1-QM',
      ),
    ];
  }
}
