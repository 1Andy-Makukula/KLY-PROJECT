/// =============================================================================
/// KithLy Global Protocol - GIFT STATE PROVIDER (Phase IV)
/// gift_provider.dart - Provider State Management for Real-Time Updates
/// =============================================================================
///
/// Location: lib/state_machine/ (as per user requirement)
/// Uses: Provider package for reactive state management
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'protocol_mapper.dart';
import '../services/kithly_api.dart';
import '../services/payment_gate.dart';

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
  double? aiConfidence;
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
    this.aiConfidence,
    required this.createdAt,
    required this.updatedAt,
  });

  UIState get uiState =>
      ProtocolMapper.mapStatus(status, zraResultCode: zraResultCode);
  double get progress => ProtocolMapper.getProgress(status);
  bool get isActive => ProtocolMapper.isActive(status);
  bool get needsAttention => ProtocolMapper.needsAttention(status);
  bool get isVerified => zraResultCode == '000' || zraResultCode == '001';
  bool get isCompleted => status == 400;
}

/// Gift state provider with real-time updates
class GiftProvider extends ChangeNotifier {
  final KithlyApiService _api;
  final PaymentGate _paymentGate;

  /// Constructor with optional dependency injection.
  /// Falls back to default instances for production use.
  GiftProvider({KithlyApiService? api, PaymentGate? paymentGate})
      : _api = api ?? KithlyApiService(),
        _paymentGate = paymentGate ?? PaymentGate.instance;
  final Map<String, Gift> _gifts = {};
  Gift? _activeGift;
  Timer? _pollTimer;
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  String? _error;

  // Getters
  List<Gift> get gifts => _gifts.values.toList();
  Gift? get activeGift => _activeGift;
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get error => _error;
  int get currentStatus => _activeGift?.status ?? 0;

  // === Verification Protocol State ===

  bool _isVerifyingInventory = false;
  int _verificationTimer = 120;
  String _verificationPhase =
      'idle'; // idle | verifying | rerouting_search | rerouted | confirmed
  Timer? _verificationCountdown;
  String? _reroutedShopName;

  bool get isVerifyingInventory => _isVerifyingInventory;
  int get verificationTimer => _verificationTimer;
  String get verificationPhase => _verificationPhase;
  String? get reroutedShopName => _reroutedShopName;

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
    _error = null;

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

  /// Process payment: 100 → 200
  Future<bool> processPayment({
    required String txId,
    required double zmwAmount,
    String paymentMethod = 'stripe',
    String displayCurrency = 'USD',
  }) async {
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      // Call payment gate (simulates Stripe/Apple Pay)
      final result = await _paymentGate.processPayment(
        txId: txId,
        zmwAmount: zmwAmount,
        paymentMethod: paymentMethod,
        displayCurrency: displayCurrency,
      );

      if (result.success) {
        // POST to Gateway to confirm payment
        // await _api.confirmPayment(txId, result.paymentRef!);

        // Update local status: 100 → 200
        updateStatus(txId, 200);

        // Start inventory verification countdown for buyer
        startVerification(txId);

        // Simulate progression through statuses for demo
        _simulateStatusProgression(txId);

        return true;
      } else {
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  /// Simulate status progression for demo purposes
  void _simulateStatusProgression(String txId) {
    // 200 → 250 after 3s (Flutterwave confirms)
    Future.delayed(const Duration(seconds: 3), () {
      updateStatus(txId, 250);
    });

    // 250 → 300 after 5s (Shop accepts → also confirms verification)
    Future.delayed(const Duration(seconds: 5), () {
      updateStatus(txId, 300);
      confirmVerification(txId);
    });

    // 300 → 310 after 7s (Rider assigned)
    Future.delayed(const Duration(seconds: 7), () {
      updateStatus(txId, 310);
    });

    // 310 → 400 after 10s (Delivered + ZRA verified)
    Future.delayed(const Duration(seconds: 10), () {
      updateStatus(
        txId,
        400,
        zraResultCode: '000',
        proofUrl: 'https://storage.kithly.com/proofs/demo.jpg',
        zraRef: 'ZRA-2026-${DateTime.now().millisecondsSinceEpoch}',
      );
    });
  }

  /// Update gift status locally (from payment/polling)
  void updateStatus(
    String txId,
    int newStatus, {
    String? zraResultCode,
    String? proofUrl,
    String? zraRef,
    double? aiConfidence,
  }) {
    final gift = _gifts[txId];
    if (gift != null) {
      gift.status = newStatus;
      gift.zraResultCode = zraResultCode ?? gift.zraResultCode;
      gift.proofUrl = proofUrl ?? gift.proofUrl;
      gift.zraRef = zraRef ?? gift.zraRef;
      gift.aiConfidence = aiConfidence ?? gift.aiConfidence;
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
          aiConfidence: response['ai_confidence']?.toDouble(),
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _verificationCountdown?.cancel();
    _api.dispose();
    super.dispose();
  }

  // === Verification Protocol Methods ===

  /// Start the 120s inventory verification countdown
  void startVerification(String txId) {
    _isVerifyingInventory = true;
    _verificationTimer = 120;
    _verificationPhase = 'verifying';
    _verificationCountdown?.cancel();

    _verificationCountdown = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onVerificationTick(txId),
    );

    notifyListeners();
  }

  /// Tick: decrement timer, trigger reroute on expiry
  void _onVerificationTick(String txId) {
    if (_verificationPhase != 'verifying') {
      _verificationCountdown?.cancel();
      return;
    }

    _verificationTimer--;
    notifyListeners();

    if (_verificationTimer <= 0) {
      _verificationCountdown?.cancel();
      _verificationPhase = 'rerouting_search';
      _isVerifyingInventory = false;
      notifyListeners();
      _simulateReroute(txId);
    }
  }

  /// Shop accepted — cancel timer, celebrate
  void confirmVerification(String txId) {
    if (_verificationPhase != 'verifying') return;

    _verificationCountdown?.cancel();
    _verificationPhase = 'confirmed';
    _isVerifyingInventory = false;
    notifyListeners();
  }

  /// Simulate finding an alternative shop (3s search)
  void _simulateReroute(String txId) {
    Future.delayed(const Duration(seconds: 3), () {
      final gift = _gifts[txId];
      if (gift != null && _verificationPhase == 'rerouting_search') {
        // Reassign shop — no double charge
        gift.shopId = 'alt-shop-${DateTime.now().millisecondsSinceEpoch}';
        gift.shopName = 'KithLy Express Hub';
        _reroutedShopName = gift.shopName;
        _verificationPhase = 'rerouted';
        gift.updatedAt = DateTime.now();
        notifyListeners();
      }
    });
  }
}
