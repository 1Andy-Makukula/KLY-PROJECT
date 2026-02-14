class OrderModel {
  final String id;
  final String recipientName;
  final String productName;
  final String collectionToken; // The "Secure Code"
  final String status; // "Paid", "Ready", "Collected"
  final double amount;
  final DateTime timestamp;

  OrderModel({
    required this.id,
    required this.recipientName,
    required this.productName,
    required this.collectionToken,
    required this.status,
    required this.amount,
    required this.timestamp,
  });
}
