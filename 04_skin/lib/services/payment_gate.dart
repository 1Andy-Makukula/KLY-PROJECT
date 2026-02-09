/// =============================================================================
/// KithLy Global Protocol - PAYMENT GATE (Phase IV)
/// payment_gate.dart - Mock Stripe/Apple Pay Handshake
/// =============================================================================
library;

import 'dart:async';

/// Payment result
class PaymentResult {
  final bool success;
  final String? paymentRef;
  final String? error;
  final double amount;
  final String currency;
  
  PaymentResult({
    required this.success,
    this.paymentRef,
    this.error,
    required this.amount,
    required this.currency,
  });
}

/// Currency rates (mock - would fetch from API)
class CurrencyConverter {
  static const Map<String, double> _rates = {
    'ZMW_USD': 0.037,  // 1 ZMW = 0.037 USD
    'ZMW_GBP': 0.029,  // 1 ZMW = 0.029 GBP
    'ZMW_EUR': 0.034,  // 1 ZMW = 0.034 EUR
  };
  
  static double convert(double zmwAmount, String toCurrency) {
    final rate = _rates['ZMW_$toCurrency'] ?? 1.0;
    return zmwAmount * rate;
  }
  
  static String formatWithConversion(double zmwAmount, String toCurrency) {
    final converted = convert(zmwAmount, toCurrency);
    final symbol = _symbols[toCurrency] ?? toCurrency;
    return '$symbol${converted.toStringAsFixed(2)}';
  }
  
  static const Map<String, String> _symbols = {
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'ZMW': 'K',
  };
}

/// Payment gateway service (MVP mock)
class PaymentGate {
  static PaymentGate? _instance;
  static PaymentGate get instance {
    _instance ??= PaymentGate._();
    return _instance!;
  }
  
  PaymentGate._();
  
  /// Simulate Stripe payment
  Future<PaymentResult> processStripePayment({
    required String txId,
    required double amount,
    required String currency,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock successful payment 95% of the time
    final success = DateTime.now().millisecond % 20 != 0;
    
    if (success) {
      final paymentRef = 'pi_${DateTime.now().millisecondsSinceEpoch}';
      return PaymentResult(
        success: true,
        paymentRef: paymentRef,
        amount: amount,
        currency: currency,
      );
    } else {
      return PaymentResult(
        success: false,
        error: 'Payment declined. Please try again.',
        amount: amount,
        currency: currency,
      );
    }
  }
  
  /// Simulate Apple Pay
  Future<PaymentResult> processApplePay({
    required String txId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return PaymentResult(
      success: true,
      paymentRef: 'ap_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: 'USD',
    );
  }
  
  /// Process payment and trigger status 100 → 200
  Future<PaymentResult> processPayment({
    required String txId,
    required double zmwAmount,
    required String paymentMethod, // 'stripe', 'apple_pay'
    String displayCurrency = 'USD',
  }) async {
    final displayAmount = CurrencyConverter.convert(zmwAmount, displayCurrency);
    
    PaymentResult result;
    
    switch (paymentMethod) {
      case 'apple_pay':
        result = await processApplePay(txId: txId, amount: displayAmount);
        break;
      case 'stripe':
      default:
        result = await processStripePayment(
          txId: txId,
          amount: displayAmount,
          currency: displayCurrency,
        );
    }
    
    if (result.success) {
      // TODO: Call Gateway to confirm payment and trigger C++ Brain
      // This would move status from 100 → 200
      // await _api.confirmPayment(txId, result.paymentRef);
    }
    
    return result;
  }
}
