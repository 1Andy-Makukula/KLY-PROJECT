/// KithLy Global Protocol - API Service
/// Connection to Python Gateway
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static String? _accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  void setToken(String token) => _accessToken = token;
  void clearToken() => _accessToken = null;

  Future<Map<String, dynamic>> createGift({
    required String receiverPhone,
    required String receiverName,
    required String shopId,
    required String productId,
    int quantity = 1,
    String? message,
  }) async {
    final idempotencyKey = const Uuid().v4();

    final response = await http.post(
      Uri.parse('$baseUrl/gifts/'),
      headers: _headers,
      body: jsonEncode({
        'receiver_phone': receiverPhone,
        'receiver_name': receiverName,
        'shop_id': shopId,
        'product_id': productId,
        'quantity': quantity,
        'message': message,
        'idempotency_key': idempotencyKey,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getGift(String txId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gifts/$txId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> listGifts({String role = 'sender'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gifts/?role=$role'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // SHOP DASHBOARD ENDPOINTS (Phase IV-Extension)
  // ===========================================================================

  /// Get shop dashboard data (revenue, pending orders)
  Future<Map<String, dynamic>> getShopDashboard(String shopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/shop/$shopId/dashboard'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  /// Get shop orders (Status 300 - Ready for Collection)
  Future<Map<String, dynamic>> getShopOrders(String shopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/shop/$shopId/orders'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  /// Cancel an order (out of stock)
  Future<Map<String, dynamic>> cancelOrder(
    String txId,
    String reason,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shop/orders/$txId/cancel'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel order: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // PRODUCT CATALOG ENDPOINTS (Phase IV-Extension)
  // ===========================================================================

  /// Get products for a specific shop
  Future<List<dynamic>> getShopProducts(String shopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/shop/$shopId/products'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // VERIFICATION HANDSHAKE (Phase III-V)
  // ===========================================================================

  /// Verify collection token (QR scan or manual entry)
  Future<Map<String, dynamic>> verifyHandshake({
    required String token,
    required String shopId,
    String verifiedBy = 'shop_scan',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verification/verify-handshake'),
      headers: _headers,
      body: jsonEncode({
        'tx_id': '', // Backend will resolve from token
        'collection_token': token,
        'shop_id': shopId,
        'verified_by': verifiedBy,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Verification failed: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // ADMIN ENDPOINTS (God Mode)
  // ===========================================================================

  /// Get pending shop approvals
  Future<List<dynamic>> getPendingShops() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/shops/pending'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load pending shops: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  /// Approve a pending shop
  Future<Map<String, dynamic>> approveShop(
    String shopId, {
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/shops/$shopId/approve'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve shop: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  /// Reject a pending shop
  Future<Map<String, dynamic>> rejectShop(
    String shopId, {
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/shops/$shopId/reject'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject shop: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  /// Get active riders with locations
  Future<List<dynamic>> getActiveRiders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/riders/active'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load riders: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }
}
