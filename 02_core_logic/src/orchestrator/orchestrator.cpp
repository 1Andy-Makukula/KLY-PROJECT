/**
 * =============================================================================
 * KithLy Global Protocol - THE HEART (Phase V)
 * orchestrator.cpp - Fail-Safe Escalation + Financial Settlement Logic
 * =============================================================================
 * 
 * Status Flow:
 *   100 (INITIATED) → Human via Flutter App
 *   150 (AGENT_INITIATED) → AI Agent via UCP Protocol
 *   100/150 → Stripe webhook → 200 (FUNDS_LOCKED)
 *   200 (FUNDS_LOCKED) → Flutterwave webhook → 250 (SETTLED)
 *   250 (SETTLED) → Shop accepts → 300 (FULFILLING)
 *   300+ → Escalation logic → 305/315
 *   400 (COMPLETED) requires ZRA verification
 */

#include "constants.h"
#include "structs.h"
#include "db_connector.h"
#include <chrono>
#include <string>
#include <iostream>

namespace Kithly {

// Extended status codes for escalation
constexpr int FORCE_CALL_PENDING = 305;
constexpr int REROUTING = 315;
constexpr int HELD_FOR_REVIEW = 800;

// Escalation thresholds
constexpr int FORCE_CALL_THRESHOLD_MINS = 5;
constexpr int REROUTE_THRESHOLD_MINS = 10;

/**
 * Transaction with timing info for escalation checks
 */
struct Transaction {
    std::string tx_id;
    int status_code;
    std::chrono::system_clock::time_point status_changed_at;
    std::string shop_id;
};

/**
 * Calculate elapsed minutes since status change
 */
int get_elapsed_minutes(const Transaction& tx) {
    auto now = std::chrono::system_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::minutes>(
        now - tx.status_changed_at
    );
    return static_cast<int>(elapsed.count());
}

/**
 * Check if transaction needs escalation
 * Returns: new status code, or 0 if no escalation needed
 */
int check_for_escalation(const Transaction& tx) {
    int elapsed_mins = get_elapsed_minutes(tx);
    
    // Status 300 (FULFILLING) → 305 (FORCE_CALL_PENDING) after 5 mins
    if (tx.status_code == Status::FULFILLING && elapsed_mins > FORCE_CALL_THRESHOLD_MINS) {
        std::cout << "[ESCALATION] tx_id=" << tx.tx_id 
                  << " | 300→305 | Triggering force call after " 
                  << elapsed_mins << " mins" << std::endl;
        return FORCE_CALL_PENDING;
    }
    
    // Status 305 → 315 (REROUTING) after 10 mins
    if (tx.status_code == FORCE_CALL_PENDING && elapsed_mins > REROUTE_THRESHOLD_MINS) {
        std::cout << "[ESCALATION] tx_id=" << tx.tx_id 
                  << " | 305→315 | Initiating reroute after " 
                  << elapsed_mins << " mins" << std::endl;
        return REROUTING;
    }
    
    return 0; // No escalation needed
}

/**
 * Process escalation and update database
 */
bool process_escalation(Transaction& tx) {
    int new_status = check_for_escalation(tx);
    
    if (new_status == 0) {
        return false; // No escalation
    }
    
    // Update in database
    if (update_status(tx.tx_id, new_status)) {
        tx.status_code = new_status;
        tx.status_changed_at = std::chrono::system_clock::now();
        
        // Trigger gateway hook for force call
        if (new_status == FORCE_CALL_PENDING) {
            // TODO: Call internal_worker to trigger Twilio
            std::cout << "[GATEWAY] POST /internal/force-call tx_id=" 
                      << tx.tx_id << std::endl;
        }
        
        return true;
    }
    
    return false;
}

/**
 * Handle Stripe webhook: 100 → 200 (FUNDS_LOCKED)
 * Only trust server-to-server webhook, not client-side success
 */
bool on_stripe_webhook_payment_confirmed(const std::string& tx_id, const std::string& payment_intent_id) {
    std::cout << "[STRIPE WEBHOOK] Payment confirmed for tx_id=" << tx_id 
              << " intent=" << payment_intent_id << std::endl;
    
    // Verify current status is 100
    // TODO: Query database for current status
    
    if (update_status(tx_id, Status::FUNDS_LOCKED)) {
        std::cout << "[STATUS] " << tx_id << " | 100 → 200 (FUNDS_LOCKED)" << std::endl;
        return true;
    }
    
    return false;
}

/**
 * Handle Flutterwave webhook: 200 → 250 (SETTLED)
 * Only after shop's mobile money account is validated
 */
bool on_flutterwave_webhook_account_verified(const std::string& tx_id, const std::string& shop_id) {
    std::cout << "[FLUTTERWAVE WEBHOOK] Account verified for shop=" << shop_id 
              << " tx_id=" << tx_id << std::endl;
    
    // Verify current status is 200 (FUNDS_LOCKED)
    // Only proceed if funds are locked
    
    if (update_status(tx_id, Status::SETTLED)) {
        std::cout << "[STATUS] " << tx_id << " | 200 → 250 (SETTLED)" << std::endl;
        std::cout << "[GATEWAY] POST /internal/notify-shop shop_id=" << shop_id << std::endl;
        return true;
    }
    
    return false;
}

/**
 * ZRA Fiscalization Interlock: Controls 340 → 400 transition
 * Returns true only if ZRA VSDC returns resultCd 000 or 001
 */
bool can_complete_delivery(const std::string& tx_id, const std::string& zra_result_code) {
    // The "Aeronautical Interlock" - delivery cannot be marked complete
    // without successful ZRA fiscalization
    
    if (zra_result_code == "000" || zra_result_code == "001") {
        std::cout << "[ZRA OK] tx_id=" << tx_id << " resultCd=" << zra_result_code 
                  << " | Interlock RELEASED" << std::endl;
        return true;
    }
    
    std::cout << "[ZRA FAIL] tx_id=" << tx_id << " resultCd=" << zra_result_code 
              << " | Interlock HELD" << std::endl;
    return false;
}

/**
 * Mark delivery complete: 340 → 400 (COMPLETED)
 * Requires ZRA verification (hard interlock)
 */
bool complete_delivery(const std::string& tx_id, const std::string& zra_result_code) {
    if (!can_complete_delivery(tx_id, zra_result_code)) {
        // Hold for review if ZRA failed
        update_status(tx_id, HELD_FOR_REVIEW);
        std::cout << "[STATUS] " << tx_id << " | → 800 (HELD_FOR_REVIEW) - ZRA interlock failed" << std::endl;
        return false;
    }
    
    if (update_status(tx_id, Status::COMPLETED)) {
        std::cout << "[STATUS] " << tx_id << " | → 400 (COMPLETED)" << std::endl;
        return true;
    }
    
    return false;
}

// =============================================================================
// 48-HOUR ESCROW WATCHDOG (Phase III-V)
// =============================================================================

constexpr int KEY_VERIFIED = 350;
constexpr int EXPIRED = 900;
constexpr int ESCROW_TIMEOUT_HOURS = 48;

/**
 * Extended Transaction with escrow data
 */
struct EscrowTransaction {
    std::string tx_id;
    int status_code;
    std::chrono::system_clock::time_point expiry_timestamp;
    std::string collection_token;
    std::string stripe_payment_ref;
    bool is_settled;
};

/**
 * Check if escrow has expired
 * Logic: If status == 200 (LOCKED) and now() > expiry_timestamp
 */
bool is_escrow_expired(const EscrowTransaction& tx) {
    if (tx.status_code != Status::FUNDS_LOCKED) {
        return false;
    }
    
    auto now = std::chrono::system_clock::now();
    return now > tx.expiry_timestamp;
}

/**
 * Process expired escrow: 200 → 900 (EXPIRED) + Stripe refund
 */
bool process_expired_escrow(EscrowTransaction& tx) {
    if (!is_escrow_expired(tx)) {
        return false;
    }
    
    std::cout << "[ESCROW EXPIRED] tx_id=" << tx.tx_id 
              << " | 48-hour deadline passed" << std::endl;
    
    // Move to EXPIRED status
    if (update_status(tx.tx_id, EXPIRED)) {
        tx.status_code = EXPIRED;
        
        // Trigger Stripe refund
        std::cout << "[STRIPE REFUND] Initiating refund for tx_id=" << tx.tx_id 
                  << " payment_ref=" << tx.stripe_payment_ref << std::endl;
        
        // TODO: Call Stripe Refund API via Gateway
        // POST /internal/refund { tx_id, stripe_payment_ref }
        
        return true;
    }
    
    return false;
}

/**
 * Verify collection token and transition to KEY_VERIFIED
 * Called when shop scans QR or enters 10-digit code
 */
bool verify_collection_token(
    const std::string& tx_id, 
    const std::string& provided_token,
    const std::string& expected_token
) {
    if (provided_token != expected_token) {
        std::cout << "[TOKEN INVALID] tx_id=" << tx_id 
                  << " | Provided token does not match" << std::endl;
        return false;
    }
    
    // Move to KEY_VERIFIED
    if (update_status(tx_id, KEY_VERIFIED)) {
        std::cout << "[STATUS] " << tx_id << " | → 350 (KEY_VERIFIED)" << std::endl;
        
        // Trigger ZRA fiscalization
        std::cout << "[GATEWAY] POST /verification/trigger-zra tx_id=" << tx_id << std::endl;
        
        // Trigger Flutterwave disbursement
        std::cout << "[GATEWAY] POST /verification/trigger-disbursement tx_id=" << tx_id << std::endl;
        
        return true;
    }
    
    return false;
}

/**
 * Run escrow watchdog (called by scheduled worker)
 * Scans all LOCKED transactions for expiry
 */
void run_escrow_watchdog() {
    std::cout << "[ESCROW WATCHDOG] Starting scan..." << std::endl;
    
    // TODO: Query database for LOCKED transactions
    // SELECT tx_id, expiry_timestamp, stripe_payment_ref 
    // FROM Global_Gifts 
    // WHERE status_code = 200
    
    // For each expired transaction, call process_expired_escrow()
    
    std::cout << "[ESCROW WATCHDOG] Scan complete" << std::endl;
}

} // namespace Kithly

