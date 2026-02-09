/// =============================================================================
/// KithLy Global Protocol - FEATURE FLAGS (Phase IV)
/// feature_flags.dart - The "Better Way" to Enable/Disable Features
/// =============================================================================
/// 
/// Compile-time flags to control feature visibility.
/// When a flag is false, the code remains healthy but hidden from users.
library;

/// Feature flags for controlling visibility of features
class FeatureFlags {
  FeatureFlags._();
  
  // ===========================================================================
  // DELIVERY FEATURES
  // ===========================================================================
  
  /// Enable manual delivery dispatch UI (Yango/Ulendo integration)
  /// Set to true when ready to expose the delivery bridge to shops
  static const bool enableManualDelivery = false;
  
  /// Enable real-time rider tracking on Flight Map
  static const bool enableRiderTracking = true;
  
  // ===========================================================================
  // SHOP FEATURES
  // ===========================================================================
  
  /// Enable shop-side order editing before collection
  static const bool enableOrderEditing = false;
  
  /// Enable shop performance analytics dashboard
  static const bool enableShopAnalytics = false;
  
  // ===========================================================================
  // ADMIN FEATURES
  // ===========================================================================
  
  /// Enable bulk shop approval actions
  static const bool enableBulkApproval = false;
  
  /// Enable admin chat with shops/riders
  static const bool enableAdminChat = false;
  
  // ===========================================================================
  // PAYMENT FEATURES
  // ===========================================================================
  
  /// Enable instant settlement (vs. T+1)
  static const bool enableInstantSettlement = false;
  
  /// Enable multi-currency display
  static const bool enableMultiCurrency = true;
  
  // ===========================================================================
  // DEBUG/DEV FEATURES
  // ===========================================================================
  
  /// Show mock data fallbacks in UI
  static const bool showMockDataBanner = true;
  
  /// Enable verbose API logging
  static const bool enableApiLogging = true;
}
