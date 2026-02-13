/// =============================================================================
/// KithLy Global Protocol - TEST FIXTURES (Phase VI)
/// gift_fixtures.dart - Test Data Factories & Mock Services
/// =============================================================================
///
/// Provides:
/// - GiftTestFixture: Factory for creating Gift objects in various states
/// - MockApiService: In-memory mock that replaces KithlyApiService for tests

import '../../lib/state_machine/gift_provider.dart';
import '../../lib/services/kithly_api.dart';

// =============================================================================
// GIFT TEST FIXTURE - Factory for test Gift objects
// =============================================================================

/// Factory class that generates Gift objects for testing.
class GiftTestFixture {
  static int _counter = 0;

  /// Create a Gift with the given status code.
  /// Defaults to Status 100 (INITIATED).
  static Gift createGift({int status = 100}) {
    _counter++;
    return Gift(
      txId: 'test-tx-$_counter',
      txRef: 'KLY-TEST-$_counter',
      status: status,
      receiverName: 'Test Receiver $_counter',
      receiverPhone: '+26097700$_counter',
      shopId: 'shop-test-$_counter',
      productId: 'prod-test-$_counter',
      productName: 'Test Gift Item $_counter',
      quantity: 1,
      unitPrice: 250.0,
      totalAmount: 250.0,
      currency: 'ZMW',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convenience: Gift at Status 100 (Initiated)
  static Gift initiated() => createGift(status: 100);

  /// Convenience: Gift at Status 200 (Paid)
  static Gift paid() => createGift(status: 200);

  /// Convenience: Gift at Status 400 (Delivered)
  static Gift delivered() => createGift(status: 400);

  /// Reset the counter (call in setUp if needed)
  static void reset() => _counter = 0;
}

// =============================================================================
// MOCK API SERVICE - Replaces KithlyApiService for unit tests
// =============================================================================

/// A mock implementation of KithlyApiService that returns fixture data
/// without making any network requests.
class MockApiService extends KithlyApiService {
  /// Tracks calls for verification
  final List<String> callLog = [];

  /// Configurable response for createGift
  Map<String, dynamic>? nextCreateGiftResponse;

  /// Configurable response for getGift
  Map<String, dynamic>? nextGetGiftResponse;

  @override
  Future<void> init() async {
    callLog.add('init');
    // No-op for tests — skip SyncManager initialization
  }

  @override
  void dispose() {
    callLog.add('dispose');
    // No-op for tests
  }

  @override
  Future<Map<String, dynamic>> createGift({
    required String receiverPhone,
    required String receiverName,
    required String shopId,
    required String productId,
    int quantity = 1,
    String? message,
  }) async {
    callLog.add('createGift');

    return nextCreateGiftResponse ??
        {
          'tx_id': 'mock-tx-${DateTime.now().millisecondsSinceEpoch}',
          'tx_ref': 'KLY-MOCK-001',
          'status': 100,
          'message': 'Gift created successfully',
        };
  }

  @override
  Future<Map<String, dynamic>> getGift(String txId) async {
    callLog.add('getGift:$txId');

    return nextGetGiftResponse ??
        {
          'tx_id': txId,
          'tx_ref': 'KLY-MOCK-001',
          'status': 100,
          'zra_result_code': null,
          'proof_url': null,
          'zra_ref': null,
          'ai_confidence': null,
        };
  }
}
