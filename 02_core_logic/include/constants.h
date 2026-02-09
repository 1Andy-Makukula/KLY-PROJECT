/**
 * =============================================================================
 * KithLy Global Protocol - THE FIRST BRICK
 * constants.h - Status Codes
 * =============================================================================
 */

#pragma once

namespace Kithly {

/**
 * Transaction Status Codes
 * 
 * 100-199: Initiation Phase
 * 200-299: Payment Phase  
 * 300-399: Fulfillment Phase
 * 400-499: Completion Phase
 * 800-899: Review/Hold Status
 * 900+: Failure/Refund
 */
enum Status {
    INITIATED        = 100,   // Human via Flutter app
    AGENT_INITIATED  = 150,   // AI Agent via UCP
    FUNDS_LOCKED     = 200,   // Stripe webhook confirmed
    SETTLED          = 250,   // Flutterwave account verified
    FULFILLING       = 300,   // Shop notified
    COMPLETED        = 400    // ZRA verified delivery
};

} // namespace Kithly
