/// KithLy Global Protocol - Flutter State Machine
/// Turns status codes (100-900) into UI changes
library;

enum GiftStatus {
  initiated(100, 'Gift Created', 'Your gift is being prepared'),
  paid(200, 'Payment Confirmed', 'Looking for a rider'),
  assigned(310, 'Rider Assigned', 'A rider is on the way to the shop'),
  pickupEnRoute(320, 'Pickup In Progress', 'Rider heading to shop'),
  pickedUp(330, 'Gift Collected', 'Your gift has been picked up'),
  deliveryEnRoute(340, 'On The Way', 'Rider is heading to the recipient'),
  delivered(400, 'Delivered', 'Gift has been handed over'),
  confirmed(500, 'Receipt Confirmed', 'Recipient confirmed the gift'),
  gratitudeSent(600, 'Thank You Received', 'A gratitude message awaits'),
  completed(700, 'Complete', 'Gift journey complete'),
  disputed(800, 'Issue Raised', 'We are looking into this'),
  resolved(900, 'Resolved', 'Issue has been resolved');

  const GiftStatus(this.code, this.title, this.description);
  
  final int code;
  final String title;
  final String description;
  
  static GiftStatus fromCode(int code) {
    return GiftStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => GiftStatus.initiated,
    );
  }
  
  bool get isActive => code >= 100 && code < 700;
  bool get isComplete => code == 700;
  bool get hasIssue => code >= 800;
}

class GiftStateMachine {
  GiftStatus _currentStatus = GiftStatus.initiated;
  final List<StatusTransition> _history = [];
  
  GiftStatus get currentStatus => _currentStatus;
  List<StatusTransition> get history => List.unmodifiable(_history);
  
  void transition(GiftStatus newStatus) {
    _history.add(StatusTransition(
      from: _currentStatus,
      to: newStatus,
      at: DateTime.now(),
    ));
    _currentStatus = newStatus;
  }
  
  double get progressPercent {
    if (_currentStatus.code >= 700) return 1.0;
    if (_currentStatus.code >= 800) return 0.0;
    return _currentStatus.code / 700.0;
  }
}

class StatusTransition {
  final GiftStatus from;
  final GiftStatus to;
  final DateTime at;
  
  StatusTransition({required this.from, required this.to, required this.at});
}
