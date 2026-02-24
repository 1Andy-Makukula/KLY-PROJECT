/// =============================================================================
/// KithLy Global Protocol - GIFT PROVIDER UNIT TEST (Phase VI)
/// gift_provider_test.dart - Verifies GiftProvider state machine via DI
/// =============================================================================
///
/// Injects MockApiService into GiftProvider to verify that createGift()
/// correctly updates the state to Status 100 without network calls.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../lib/state_machine/gift_provider.dart';
import '../../../lib/services/payment_gate.dart';
import '../../fixtures/gift_fixtures.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late MockApiService mockApi;
  late GiftProvider provider;

  setUp(() {
    GiftTestFixture.reset();
    mockApi = MockApiService();

    // Inject mock API service into GiftProvider via constructor DI
    provider = GiftProvider(
      api: mockApi,
      paymentGate: PaymentGate.instance,
    );
  });

  group('GiftProvider - createGift', () {
    test('createGift sets status to 100 (INITIATED)', () async {
      // Act
      final gift = await provider.createGift(
        receiverPhone: '+260977111222',
        receiverName: 'John Banda',
        shopId: 'shop-001',
        productId: 'prod-001',
        productName: 'Birthday Cake',
        unitPrice: 350.0,
      );

      // Assert
      expect(gift.status, equals(100));
      expect(gift.receiverName, equals('John Banda'));
      expect(gift.totalAmount, equals(350.0));
      expect(provider.activeGift, isNotNull);
      expect(provider.activeGift!.txId, equals(gift.txId));
      expect(provider.gifts.length, equals(1));
    });
  });

  group('GiftTestFixture', () {
    test('creates gift with correct status', () {
      final gift100 = GiftTestFixture.initiated();
      final gift200 = GiftTestFixture.paid();
      final gift400 = GiftTestFixture.delivered();

      expect(gift100.status, equals(100));
      expect(gift200.status, equals(200));
      expect(gift400.status, equals(400));
    });
  });
}
