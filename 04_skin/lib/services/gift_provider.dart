/// =============================================================================
/// KithLy Global Protocol - GIFT STATE PROVIDER (Phase IV)
/// gift_provider.dart - Provider State Management for Real-Time Updates
/// =============================================================================
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../state_machine/protocol_mapper.dart';
import 'kithly_api.dart';

/// Gift model with reactive status
class Gift {
  final String txId;
  final String txRef;
  int status;
  String? zraResultCode;
  final String receiverName;
  final String receiverPhone;
  String shopId;
  String shopName;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String currency;
  String? proofUrl;
  String? zraRef;
  DateTime createdAt;
  DateTime updatedAt;

  Gift({
    required this.txId,
    required this.txRef,
    required this.status,
    this.zraResultCode,
    required this.receiverName,
    required this.receiverPhone,
    required this.shopId,
    this.shopName = '',
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.currency = 'ZMW',
    this.proofUrl,
    this.zraRef,
    required this.createdAt,
    required this.updatedAt,
  });

  UIState get uiState =>
      ProtocolMapper.mapStatus(status, zraResultCode: zraResultCode);
  double get progress => ProtocolMapper.getProgress(status);
  bool get isActive => ProtocolMapper.isActive(status);
  bool get needsAttention => ProtocolMapper.needsAttention(status);
}

/// Gift state provider with real-time updates
class GiftProvider extends ChangeNotifier {
  final KithlyApiService _api = KithlyApiService();

  final Map<String, Gift> _gifts = {};
  Gift? _activeGift;
  Timer? _pollTimer;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Gift> get gifts => _gifts.values.toList();
  Gift? get activeGift => _activeGift;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize provider
  Future<void> init() async {
    await _api.init();
  }

  /// Create a new gift (Status: 100)
  Future<Gift> createGift({
    required String receiverPhone,
    required String receiverName,
    required String shopId,
    required String productId,
    required String productName,
    required double unitPrice,
    int quantity = 1,
    String? message,
  }) async {
    _setLoading(true);

    try {
      final response = await _api.createGift(
        receiverPhone: receiverPhone,
        receiverName: receiverName,
        shopId: shopId,
        productId: productId,
        quantity: quantity,
        message: message,
      );

      final gift = Gift(
        txId: response['tx_id'],
        txRef: response['tx_ref'],
        status: 100, // INITIATED
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        shopId: shopId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: unitPrice * quantity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _gifts[gift.txId] = gift;
      _activeGift = gift;
      _startPolling(gift.txId);

      notifyListeners();
      return gift;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update gift status locally (from payment/polling)
  void updateStatus(String txId, int newStatus,
      {String? zraResultCode, String? proofUrl, String? zraRef}) {
    final gift = _gifts[txId];
    if (gift != null) {
      gift.status = newStatus;
      gift.zraResultCode = zraResultCode ?? gift.zraResultCode;
      gift.proofUrl = proofUrl ?? gift.proofUrl;
      gift.zraRef = zraRef ?? gift.zraRef;
      gift.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Start polling for status updates
  void _startPolling(String txId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollStatus(txId),
    );
  }

  /// Poll gateway for status update
  Future<void> _pollStatus(String txId) async {
    try {
      final response = await _api.getGift(txId);
      final newStatus = response['status'] as int;

      if (_gifts[txId]?.status != newStatus) {
        updateStatus(
          txId,
          newStatus,
          zraResultCode: response['zra_result_code'],
          proofUrl: response['proof_url'],
          zraRef: response['zra_ref'],
        );
      }

      // Stop polling if complete or failed
      if (newStatus >= 700 || newStatus == 900) {
        _pollTimer?.cancel();
      }
    } catch (e) {
      // Ignore polling errors
    }
  }

  /// Set active gift for tracking
  void setActiveGift(String txId) {
    _activeGift = _gifts[txId];
    if (_activeGift != null) {
      _startPolling(txId);
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }
}
