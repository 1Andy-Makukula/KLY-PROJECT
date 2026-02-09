/// =============================================================================
/// KithLy Global Protocol - PROTOCOL MAPPER (Phase IV)
/// protocol_mapper.dart - Maps C++ Status Codes to UI States
/// =============================================================================
library;

import 'package:flutter/material.dart';

/// Status codes from C++ Core (constants.h)
class KithlyStatus {
  static const int INITIATED = 100;
  static const int PAID = 200;
  static const int ASSIGNED = 310;
  static const int PICKUP_EN_ROUTE = 320;
  static const int PICKED_UP = 330;
  static const int DELIVERY_EN_ROUTE = 340;
  static const int FULFILLING = 300;
  static const int FORCE_CALL_PENDING = 305;
  static const int REROUTING = 315;
  static const int COMPLETED = 400;
  static const int CONFIRMED = 500;
  static const int GRATITUDE_SENT = 600;
  static const int DONE = 700;
  static const int HELD_FOR_REVIEW = 800;
  static const int RESOLVED = 900;
}

/// UI State for a status code
class UIState {
  final String message;
  final Color color;
  final IconData icon;
  final bool isPulsing;
  final bool isBlinking;
  final bool showMap;
  final String? zraStatus;
  
  const UIState({
    required this.message,
    required this.color,
    required this.icon,
    this.isPulsing = false,
    this.isBlinking = false,
    this.showMap = false,
    this.zraStatus,
  });
}

/// Maps C++ Status enums to UI states
class ProtocolMapper {
  /// Get UI state for a status code
  static UIState mapStatus(int statusCode, {String? zraResultCode}) {
    switch (statusCode) {
      // === Active States ===
      case KithlyStatus.INITIATED:
        return const UIState(
          message: "Gift Created",
          color: Color(0xFF6B7280),
          icon: Icons.card_giftcard,
        );
        
      case KithlyStatus.PAID:
        return const UIState(
          message: "Payment Confirmed",
          color: Color(0xFF10B981),
          icon: Icons.payment,
        );
        
      case KithlyStatus.ASSIGNED:
        return const UIState(
          message: "Rider Assigned",
          color: Color(0xFF3B82F6),
          icon: Icons.person_pin,
        );
        
      case KithlyStatus.PICKUP_EN_ROUTE:
        return const UIState(
          message: "Rider Heading to Shop",
          color: Color(0xFF3B82F6),
          icon: Icons.directions_bike,
          isPulsing: true,
        );
        
      case KithlyStatus.PICKED_UP:
        return const UIState(
          message: "Gift Collected",
          color: Color(0xFF8B5CF6),
          icon: Icons.shopping_bag,
        );
        
      case KithlyStatus.DELIVERY_EN_ROUTE:
        return const UIState(
          message: "On The Way to Receiver",
          color: Color(0xFF8B5CF6),
          icon: Icons.local_shipping,
          isPulsing: true,
        );
      
      // === Escalation States ===
      case KithlyStatus.FULFILLING:
        return const UIState(
          message: "Notifying Shop...",
          color: Color(0xFFF59E0B), // Amber
          icon: Icons.notifications_active,
          isPulsing: true,
        );
        
      case KithlyStatus.FORCE_CALL_PENDING:
        return const UIState(
          message: "Escalating: Triggering Voice Call...",
          color: Color(0xFFEF4444), // Red
          icon: Icons.phone_callback,
          isBlinking: true,
        );
        
      case KithlyStatus.REROUTING:
        return const UIState(
          message: "Shop Unavailable. Finding Nearest Alternative...",
          color: Color(0xFFF97316), // Orange
          icon: Icons.alt_route,
          showMap: true,
        );
      
      // === Success States ===
      case KithlyStatus.COMPLETED:
        final zraVerified = zraResultCode == '000' || zraResultCode == '001';
        return UIState(
          message: zraVerified 
              ? "Delivery Verified by ZRA & AI" 
              : "Delivered",
          color: const Color(0xFF10B981), // Green
          icon: Icons.verified,
          zraStatus: zraVerified ? "TAX_VERIFIED" : null,
        );
        
      case KithlyStatus.CONFIRMED:
        return const UIState(
          message: "Receipt Confirmed by Receiver",
          color: Color(0xFF10B981),
          icon: Icons.how_to_reg,
        );
        
      case KithlyStatus.GRATITUDE_SENT:
        return const UIState(
          message: "Thank You Received!",
          color: Color(0xFFEC4899), // Pink
          icon: Icons.favorite,
        );
        
      case KithlyStatus.DONE:
        return const UIState(
          message: "Gift Journey Complete",
          color: Color(0xFF10B981),
          icon: Icons.celebration,
        );
      
      // === Review States ===
      case KithlyStatus.HELD_FOR_REVIEW:
        return const UIState(
          message: "Under Review",
          color: Color(0xFFEF4444),
          icon: Icons.pending_actions,
          isBlinking: true,
        );
        
      case KithlyStatus.RESOLVED:
        return const UIState(
          message: "Issue Resolved",
          color: Color(0xFF6B7280),
          icon: Icons.check_circle_outline,
        );
        
      default:
        return const UIState(
          message: "Unknown Status",
          color: Color(0xFF6B7280),
          icon: Icons.help_outline,
        );
    }
  }
  
  /// Check if status indicates active delivery
  static bool isActive(int statusCode) {
    return statusCode >= 100 && statusCode < 700;
  }
  
  /// Check if status needs attention
  static bool needsAttention(int statusCode) {
    return statusCode == KithlyStatus.FORCE_CALL_PENDING ||
           statusCode == KithlyStatus.REROUTING ||
           statusCode == KithlyStatus.HELD_FOR_REVIEW;
  }
  
  /// Get progress percentage (0.0 - 1.0)
  static double getProgress(int statusCode) {
    if (statusCode >= 700) return 1.0;
    if (statusCode >= 800) return 0.0;
    
    final progressMap = {
      100: 0.1,
      200: 0.2,
      300: 0.35,
      305: 0.4,
      310: 0.45,
      315: 0.45,
      320: 0.5,
      330: 0.6,
      340: 0.75,
      400: 0.85,
      500: 0.9,
      600: 0.95,
    };
    
    return progressMap[statusCode] ?? 0.0;
  }
}
