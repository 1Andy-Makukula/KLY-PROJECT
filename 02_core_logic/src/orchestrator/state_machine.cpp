/**
 * =============================================================================
 * KithLy Global Protocol - LAYER 2: THE BRAIN (C++23)
 * orchestrator/state_machine.cpp - Switch-Case 100-900 Logic
 * =============================================================================
 */

#include "../include/constants.h"
#include "../include/structs.h"
#include "../include/db_connector.h"

#include <iostream>
#include <chrono>

namespace kithly {
namespace orchestrator {

/**
 * The State Machine Orchestrator
 * Handles all gift status transitions according to the protocol
 */
class StateMachine {
public:
    StateMachine(
        std::shared_ptr<db::GiftRepository> gift_repo,
        std::shared_ptr<db::ShopRepository> shop_repo,
        std::shared_ptr<db::EvidenceRepository> evidence_repo
    ) : gift_repo_(gift_repo), shop_repo_(shop_repo), evidence_repo_(evidence_repo) {}

    /**
     * Process a status transition request
     * The heart of the KithLy Protocol
     */
    Result<GiftTransaction> process_transition(
        const UUID& tx_id,
        GiftStatus target_status,
        int expected_version,
        std::optional<UUID> actor_id = std::nullopt
    ) {
        // 1. Fetch current state
        auto current = gift_repo_->find_by_id(tx_id);
        if (!current.success) {
            return Result<GiftTransaction>::fail("Transaction not found: " + tx_id);
        }
        
        auto& gift = *current.value;
        
        // 2. Validate transition
        if (!is_valid_transition(gift.status, target_status)) {
            return Result<GiftTransaction>::fail(
                "Invalid transition from " + 
                std::string(STATUS_NAMES.at(gift.status)) + 
                " to " + 
                std::string(STATUS_NAMES.at(target_status))
            );
        }
        
        // 3. Optimistic lock check
        if (gift.version != expected_version) {
            return Result<GiftTransaction>::fail("Version mismatch - transaction was modified");
        }
        
        // 4. Execute status-specific logic
        switch (target_status) {
            case GiftStatus::PAID:
                return handle_payment_confirmed(gift);
                
            case GiftStatus::ASSIGNED:
                if (!actor_id) {
                    return Result<GiftTransaction>::fail("Rider ID required for assignment");
                }
                return handle_rider_assigned(gift, *actor_id);
                
            case GiftStatus::PICKUP_EN_ROUTE:
                return handle_pickup_started(gift);
                
            case GiftStatus::PICKED_UP:
                return handle_picked_up(gift);
                
            case GiftStatus::DELIVERY_EN_ROUTE:
                return handle_delivery_started(gift);
                
            case GiftStatus::DELIVERED:
                return handle_delivered(gift);
                
            case GiftStatus::CONFIRMED:
                return handle_confirmed(gift);
                
            case GiftStatus::GRATITUDE_SENT:
                return handle_gratitude_recorded(gift);
                
            case GiftStatus::COMPLETED:
                return handle_completed(gift);
                
            case GiftStatus::DISPUTED:
                return handle_dispute_raised(gift);
                
            case GiftStatus::RESOLVED:
                return handle_dispute_resolved(gift);
                
            default:
                return Result<GiftTransaction>::fail("Unknown target status");
        }
    }

private:
    std::shared_ptr<db::GiftRepository> gift_repo_;
    std::shared_ptr<db::ShopRepository> shop_repo_;
    std::shared_ptr<db::EvidenceRepository> evidence_repo_;

    // Status-specific handlers
    Result<GiftTransaction> handle_payment_confirmed(GiftTransaction& gift) {
        gift.paid_at = std::chrono::system_clock::now();
        return gift_repo_->update_status(gift.tx_id, GiftStatus::PAID, gift.version);
    }
    
    Result<GiftTransaction> handle_rider_assigned(GiftTransaction& gift, const UUID& rider_id) {
        gift.rider_id = rider_id;
        gift.assigned_at = std::chrono::system_clock::now();
        auto assigned = gift_repo_->assign_rider(gift.tx_id, rider_id);
        if (!assigned.success) return assigned;
        return gift_repo_->update_status(gift.tx_id, GiftStatus::ASSIGNED, gift.version);
    }
    
    Result<GiftTransaction> handle_pickup_started(GiftTransaction& gift) {
        return gift_repo_->update_status(gift.tx_id, GiftStatus::PICKUP_EN_ROUTE, gift.version);
    }
    
    Result<GiftTransaction> handle_picked_up(GiftTransaction& gift) {
        gift.picked_up_at = std::chrono::system_clock::now();
        // TODO: Verify pickup evidence exists
        return gift_repo_->update_status(gift.tx_id, GiftStatus::PICKED_UP, gift.version);
    }
    
    Result<GiftTransaction> handle_delivery_started(GiftTransaction& gift) {
        return gift_repo_->update_status(gift.tx_id, GiftStatus::DELIVERY_EN_ROUTE, gift.version);
    }
    
    Result<GiftTransaction> handle_delivered(GiftTransaction& gift) {
        gift.delivered_at = std::chrono::system_clock::now();
        // TODO: Verify delivery evidence exists
        return gift_repo_->update_status(gift.tx_id, GiftStatus::DELIVERED, gift.version);
    }
    
    Result<GiftTransaction> handle_confirmed(GiftTransaction& gift) {
        gift.confirmed_at = std::chrono::system_clock::now();
        return gift_repo_->update_status(gift.tx_id, GiftStatus::CONFIRMED, gift.version);
    }
    
    Result<GiftTransaction> handle_gratitude_recorded(GiftTransaction& gift) {
        // TODO: Verify gratitude message exists
        return gift_repo_->update_status(gift.tx_id, GiftStatus::GRATITUDE_SENT, gift.version);
    }
    
    Result<GiftTransaction> handle_completed(GiftTransaction& gift) {
        gift.completed_at = std::chrono::system_clock::now();
        return gift_repo_->update_status(gift.tx_id, GiftStatus::COMPLETED, gift.version);
    }
    
    Result<GiftTransaction> handle_dispute_raised(GiftTransaction& gift) {
        // TODO: Create dispute record
        return gift_repo_->update_status(gift.tx_id, GiftStatus::DISPUTED, gift.version);
    }
    
    Result<GiftTransaction> handle_dispute_resolved(GiftTransaction& gift) {
        // TODO: Update dispute record
        return gift_repo_->update_status(gift.tx_id, GiftStatus::RESOLVED, gift.version);
    }
};

} // namespace orchestrator
} // namespace kithly
