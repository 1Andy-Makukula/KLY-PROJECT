/// =============================================================================
/// KithLy Global Protocol - CURRENCY SERVICE (Phase IV)
/// currency_service.dart - Client-Side Currency Conversion
/// =============================================================================
library;

/// Currency conversion rates (synced from Gateway Oracle)
class CurrencyService {
  static CurrencyService? _instance;
  static CurrencyService get instance {
    _instance ??= CurrencyService._();
    return _instance!;
  }
  
  CurrencyService._();
  
  // Rates from Gateway (with 1.5% safety buffer applied)
  Map<String, double> _rates = {
    'ZMW_USD': 0.0375,  // 1 ZMW = 0.0375 USD
    'ZMW_GBP': 0.0294,  // 1 ZMW = 0.0294 GBP
    'ZMW_EUR': 0.0345,  // 1 ZMW = 0.0345 EUR
  };
  
  DateTime _lastUpdated = DateTime.now();
  
  /// Update rates from Gateway
  void updateRates(Map<String, double> newRates) {
    _rates = newRates;
    _lastUpdated = DateTime.now();
  }
  
  /// Convert ZMW to target currency
  double convert(double zmwAmount, String toCurrency) {
    final key = 'ZMW_$toCurrency';
    final rate = _rates[key] ?? 1.0;
    return zmwAmount * rate;
  }
  
  /// Format with currency symbol
  String format(double zmwAmount, String currency) {
    final converted = convert(zmwAmount, currency);
    final symbol = _symbols[currency] ?? currency;
    return '$symbol${converted.toStringAsFixed(2)}';
  }
  
  /// Get formatted prices in all currencies
  Map<String, String> getAllPrices(double zmwAmount) {
    return {
      'ZMW': 'K${zmwAmount.toStringAsFixed(2)}',
      'USD': format(zmwAmount, 'USD'),
      'GBP': format(zmwAmount, 'GBP'),
      'EUR': format(zmwAmount, 'EUR'),
    };
  }
  
  static const Map<String, String> _symbols = {
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'ZMW': 'K',
  };
  
  static const Map<String, String> _flags = {
    'USD': '🇺🇸',
    'GBP': '🇬🇧',
    'EUR': '🇪🇺',
    'ZMW': '🇿🇲',
  };
  
  String getFlag(String currency) => _flags[currency] ?? '🌍';
  String getSymbol(String currency) => _symbols[currency] ?? currency;
  
  bool get isStale => 
      DateTime.now().difference(_lastUpdated).inMinutes > 5;
}
