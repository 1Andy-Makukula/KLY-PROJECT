import '../models/order_model.dart';

class MockShopService {
  // Simulate a network delay (so we can see the loading shimmer)
  Future<List<OrderModel>> getLiveOrders() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      OrderModel(
        id: "ORDER-8821",
        recipientName: "Chanda Mwale",
        productName: "Chocolate Fudge Cake (2kg)",
        collectionToken: "KLY-8821",
        status: "PAID", // Status 200 -> Needs Baking
        amount: 450.00,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      OrderModel(
        id: "ORDER-8822",
        recipientName: "Sarah K.",
        productName: "Red Velvet Cupcakes (6x)",
        collectionToken: "KLY-8822",
        status: "READY", // Status 400 -> Waiting for Rider
        amount: 120.00,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      OrderModel(
        id: "ORDER-8824",
        recipientName: "John Doe",
        productName: "Anniversary Bouquet",
        collectionToken: "KLY-8824",
        status: "COLLECTED", // Status 500 -> History
        amount: 850.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
