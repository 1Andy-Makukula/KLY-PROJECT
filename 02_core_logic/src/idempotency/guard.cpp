/**
 * =============================================================================
 * KithLy Global Protocol - LAYER 2: THE BRAIN (C++23)
 * idempotency/guard.cpp - Double-Spend Protection
 * =============================================================================
 */

#include "../include/constants.h"
#include "../include/structs.h"
#include "../include/db_connector.h"

#include <mutex>
#include <unordered_map>
#include <chrono>

namespace kithly {
namespace idempotency {

/**
 * Idempotency Guard
 * Prevents duplicate processing of the same request
 * Critical for payment safety and gift creation
 */
class IdempotencyGuard {
public:
    explicit IdempotencyGuard(std::shared_ptr<db::GiftRepository> gift_repo)
        : gift_repo_(gift_repo) {}

    /**
     * Result of idempotency check
     */
    struct CheckResult {
        bool is_duplicate;
        std::optional<GiftTransaction> existing_transaction;
    };

    /**
     * Check if a request is a duplicate
     * Returns existing transaction if found
     */
    Result<CheckResult> check(const UUID& idempotency_key) {
        // First check in-memory cache (hot path)
        {
            std::shared_lock lock(cache_mutex_);
            auto it = cache_.find(idempotency_key);
            if (it != cache_.end()) {
                auto age = std::chrono::steady_clock::now() - it->second.cached_at;
                if (age < CACHE_TTL) {
                    return Result<CheckResult>::ok({true, it->second.transaction});
                }
            }
        }
        
        // Check database (cold path)
        auto db_result = gift_repo_->find_by_idempotency_key(idempotency_key);
        if (!db_result.success) {
            return Result<CheckResult>::fail(db_result.error.value_or("Database error"));
        }
        
        if (db_result.value->has_value()) {
            // Found in DB - cache it and return
            auto& tx = **db_result.value;
            cache_transaction(idempotency_key, tx);
            return Result<CheckResult>::ok({true, tx});
        }
        
        // Not a duplicate
        return Result<CheckResult>::ok({false, std::nullopt});
    }

    /**
     * Reserve an idempotency key before processing
     * Prevents race conditions
     */
    Result<bool> reserve(const UUID& idempotency_key) {
        std::unique_lock lock(cache_mutex_);
        
        // Check if already reserved
        if (reservations_.find(idempotency_key) != reservations_.end()) {
            return Result<bool>::fail("Key already reserved - concurrent request in progress");
        }
        
        // Reserve with timestamp
        reservations_[idempotency_key] = std::chrono::steady_clock::now();
        
        // Clean up old reservations
        cleanup_expired_reservations();
        
        return Result<bool>::ok(true);
    }

    /**
     * Release a reservation (used when processing fails)
     */
    void release(const UUID& idempotency_key) {
        std::unique_lock lock(cache_mutex_);
        reservations_.erase(idempotency_key);
    }

    /**
     * Commit a successful transaction to cache
     */
    void commit(const UUID& idempotency_key, const GiftTransaction& tx) {
        std::unique_lock lock(cache_mutex_);
        reservations_.erase(idempotency_key);
        cache_transaction(idempotency_key, tx);
    }

    /**
     * RAII guard for reservation
     */
    class ReservationGuard {
    public:
        ReservationGuard(IdempotencyGuard& parent, const UUID& key)
            : parent_(parent), key_(key), committed_(false) {}
        
        ~ReservationGuard() {
            if (!committed_) {
                parent_.release(key_);
            }
        }
        
        void commit(const GiftTransaction& tx) {
            parent_.commit(key_, tx);
            committed_ = true;
        }
        
    private:
        IdempotencyGuard& parent_;
        UUID key_;
        bool committed_;
    };

    ReservationGuard make_guard(const UUID& key) {
        return ReservationGuard(*this, key);
    }

private:
    std::shared_ptr<db::GiftRepository> gift_repo_;
    
    // In-memory cache for hot path
    struct CacheEntry {
        GiftTransaction transaction;
        std::chrono::steady_clock::time_point cached_at;
    };
    
    std::unordered_map<UUID, CacheEntry> cache_;
    std::unordered_map<UUID, std::chrono::steady_clock::time_point> reservations_;
    mutable std::shared_mutex cache_mutex_;
    
    static constexpr auto CACHE_TTL = std::chrono::hours(config::IDEMPOTENCY_WINDOW_HOURS);
    static constexpr auto RESERVATION_TTL = std::chrono::seconds(30);
    
    void cache_transaction(const UUID& key, const GiftTransaction& tx) {
        cache_[key] = {tx, std::chrono::steady_clock::now()};
    }
    
    void cleanup_expired_reservations() {
        auto now = std::chrono::steady_clock::now();
        for (auto it = reservations_.begin(); it != reservations_.end(); ) {
            if (now - it->second > RESERVATION_TTL) {
                it = reservations_.erase(it);
            } else {
                ++it;
            }
        }
    }
};

/**
 * Process a gift creation with idempotency protection
 */
template<typename Func>
Result<GiftTransaction> with_idempotency(
    IdempotencyGuard& guard,
    const UUID& idempotency_key,
    Func&& create_func
) {
    // 1. Check for duplicate
    auto check = guard.check(idempotency_key);
    if (!check.success) {
        return Result<GiftTransaction>::fail(check.error.value_or("Check failed"));
    }
    
    if (check.value->is_duplicate) {
        // Return existing transaction (idempotent behavior)
        return Result<GiftTransaction>::ok(*check.value->existing_transaction);
    }
    
    // 2. Reserve the key
    auto reserve = guard.reserve(idempotency_key);
    if (!reserve.success) {
        return Result<GiftTransaction>::fail(reserve.error.value_or("Reservation failed"));
    }
    
    auto reservation = guard.make_guard(idempotency_key);
    
    // 3. Execute the creation
    try {
        auto result = create_func();
        if (result.success) {
            reservation.commit(*result.value);
        }
        return result;
    } catch (const std::exception& e) {
        return Result<GiftTransaction>::fail(e.what());
    }
}

} // namespace idempotency
} // namespace kithly
