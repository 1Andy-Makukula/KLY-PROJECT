/**
 * =============================================================================
 * KithLy Global Protocol - ORCHESTRATOR (Phase V)
 * orchestrator.cpp - Re-routing Engine & Baker's State Machine
 * =============================================================================
 * 
 * Core intelligence layer implementing:
 * - Automatic shop re-routing when declined (Status 910 → 106)
 * - PostGIS proximity search within 5km
 * - Shadow Lock inventory management
 * - Baker's Protocol state (Status 110)
 * 
 * Build: g++ -O3 -std=c++17 orchestrator.cpp -lpqxx -lpq -o orchestrator
 * =============================================================================
 */

#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include <optional>
#include <pqxx/pqxx>

namespace kithly {

// =============================================================================
// STATUS CODES
// =============================================================================

enum class OrderStatus {
    PENDING = 100,
    AWAITING_SHOP_ACCEPTANCE = 110,  // Baker's Protocol
    ALT_FOUND = 106,                  // Re-route found
    CONFIRMED = 200,
    READY_FOR_COLLECTION = 300,
    COMPLETED = 400,
    DECLINED = 910,
    CANCELLED = 900
};

// =============================================================================
// DATA STRUCTURES
// =============================================================================

struct Shop {
    std::string shop_id;
    std::string name;
    double latitude;
    double longitude;
    std::string category_id;
    std::string tier;
    double performance_score;
};

struct Order {
    std::string tx_id;
    std::string shop_id;
    std::string recipient_id;
    std::string category_id;
    int status_code;
    double recipient_lat;
    double recipient_lon;
    bool auto_reroute;
    std::string original_shop_id;
    std::string alternative_shop_id;
};

struct RerouteResult {
    bool found;
    std::string alternative_shop_id;
    std::string shop_name;
    double distance_diff_km;
    std::chrono::microseconds search_time;
};

// =============================================================================
// DATABASE CONNECTION
// =============================================================================

class Database {
private:
    std::unique_ptr<pqxx::connection> conn_;
    
public:
    Database(const std::string& connection_string) {
        conn_ = std::make_unique<pqxx::connection>(connection_string);
    }
    
    pqxx::connection& connection() { return *conn_; }
};

// =============================================================================
// RE-ROUTING ENGINE
// =============================================================================
// Target: < 50ms execution time

class ReroutingEngine {
private:
    Database& db_;
    static constexpr double SEARCH_RADIUS_KM = 5.0;
    
    /**
     * PostGIS query to find alternative shops within 5km
     * Requirement: Complete in < 50ms
     */
    std::string build_proximity_query(
        double lat, 
        double lon, 
        const std::string& category_id,
        const std::string& exclude_shop_id
    ) {
        // PostGIS ST_DWithin is optimized for spatial index
        return R"(
            SELECT 
                s.shop_id,
                s.name,
                s.latitude,
                s.longitude,
                s.performance_score,
                ST_Distance(
                    s.location::geography,
                    ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
                ) / 1000.0 as distance_km
            FROM Shops s
            WHERE s.category_id = $3
              AND s.shop_id != $4
              AND s.admin_approval_status = 'approved'
              AND s.is_verified = true
              AND ST_DWithin(
                  s.location::geography,
                  ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
                  $5  -- 5km in meters
              )
            ORDER BY s.performance_score DESC, distance_km ASC
            LIMIT 1
        )";
    }
    
public:
    ReroutingEngine(Database& db) : db_(db) {}
    
    /**
     * Search for alternative shop within 5km
     * Called when: Status == 910 (Declined) AND auto_reroute == true
     */
    RerouteResult find_alternative(const Order& order, double original_distance_km) {
        auto start = std::chrono::high_resolution_clock::now();
        
        RerouteResult result{false, "", "", 0.0, std::chrono::microseconds(0)};
        
        try {
            pqxx::work txn(db_.connection());
            
            // Execute PostGIS proximity search
            auto rows = txn.exec_params(
                build_proximity_query(
                    order.recipient_lat,
                    order.recipient_lon,
                    order.category_id,
                    order.shop_id
                ),
                order.recipient_lon,  // $1 - Note: PostGIS uses lon,lat
                order.recipient_lat,  // $2
                order.category_id,    // $3
                order.shop_id,        // $4 - exclude declined shop
                SEARCH_RADIUS_KM * 1000  // $5 - meters
            );
            
            if (!rows.empty()) {
                auto row = rows[0];
                result.found = true;
                result.alternative_shop_id = row["shop_id"].as<std::string>();
                result.shop_name = row["name"].as<std::string>();
                
                double new_distance = row["distance_km"].as<double>();
                result.distance_diff_km = new_distance - original_distance_km;
            }
            
            txn.commit();
            
        } catch (const std::exception& e) {
            std::cerr << "[REROUTE] Error: " << e.what() << std::endl;
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        result.search_time = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
        
        // Log performance
        std::cout << "[REROUTE] Search completed in " 
                  << result.search_time.count() << "µs" << std::endl;
        
        return result;
    }
    
    /**
     * Execute shadow lock on alternative shop's inventory
     * Prevents race conditions during re-route confirmation
     */
    bool shadow_lock_inventory(const std::string& alternative_shop_id, const std::string& tx_id) {
        try {
            pqxx::work txn(db_.connection());
            
            // Create temporary reservation
            txn.exec_params(R"(
                INSERT INTO Inventory_Locks (shop_id, tx_id, locked_at, expires_at)
                VALUES ($1, $2, NOW(), NOW() + INTERVAL '15 minutes')
                ON CONFLICT (shop_id, tx_id) DO UPDATE
                SET locked_at = NOW(), expires_at = NOW() + INTERVAL '15 minutes'
            )", alternative_shop_id, tx_id);
            
            txn.commit();
            
            std::cout << "[SHADOW_LOCK] Locked inventory for shop " 
                      << alternative_shop_id << " (tx: " << tx_id << ")" << std::endl;
            
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "[SHADOW_LOCK] Error: " << e.what() << std::endl;
            return false;
        }
    }
    
    /**
     * Update order status and set alternative shop
     */
    bool update_order_reroute(const std::string& tx_id, const RerouteResult& result) {
        try {
            pqxx::work txn(db_.connection());
            
            std::string distance_diff = (result.distance_diff_km >= 0 ? "+" : "") 
                                       + std::to_string(result.distance_diff_km) + "km";
            
            txn.exec_params(R"(
                UPDATE Global_Gifts
                SET status_code = $1,
                    alternative_shop_id = $2,
                    re_route_distance_diff = $3,
                    rerouted_at = NOW()
                WHERE tx_id = $4
            )", 
                static_cast<int>(OrderStatus::ALT_FOUND),
                result.alternative_shop_id,
                distance_diff,
                tx_id
            );
            
            txn.commit();
            
            std::cout << "[REROUTE] Order " << tx_id 
                      << " → Status 106 (ALT_FOUND)" << std::endl;
            
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "[REROUTE] Update error: " << e.what() << std::endl;
            return false;
        }
    }
};

// =============================================================================
// BAKER'S STATE MACHINE
// =============================================================================
// Handles Status 110: AWAITING_SHOP_ACCEPTANCE

class BakersProtocol {
private:
    Database& db_;
    
public:
    BakersProtocol(Database& db) : db_(db) {}
    
    /**
     * Check if order requires shop acceptance
     * Returns true if the product is made-to-order
     */
    bool requires_acceptance(const std::string& product_id) {
        try {
            pqxx::work txn(db_.connection());
            
            auto rows = txn.exec_params(R"(
                SELECT is_made_to_order FROM Products WHERE sku_id = $1
            )", product_id);
            
            if (!rows.empty()) {
                return rows[0]["is_made_to_order"].as<bool>();
            }
            
            return false;
            
        } catch (const std::exception& e) {
            std::cerr << "[BAKER] Error checking product: " << e.what() << std::endl;
            return false;
        }
    }
    
    /**
     * Set order to AWAITING_SHOP_ACCEPTANCE (110)
     * Funds are authorized but NOT captured
     */
    bool set_awaiting_acceptance(const std::string& tx_id) {
        try {
            pqxx::work txn(db_.connection());
            
            txn.exec_params(R"(
                UPDATE Global_Gifts
                SET status_code = $1,
                    acceptance_deadline = NOW() + INTERVAL '2 hours'
                WHERE tx_id = $2
            )", static_cast<int>(OrderStatus::AWAITING_SHOP_ACCEPTANCE), tx_id);
            
            txn.commit();
            
            std::cout << "[BAKER] Order " << tx_id 
                      << " → Status 110 (AWAITING_SHOP_ACCEPTANCE)" << std::endl;
            
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "[BAKER] Error: " << e.what() << std::endl;
            return false;
        }
    }
    
    /**
     * Shop accepts the order
     * Triggers: Payment capture, status → 200 (CONFIRMED)
     */
    bool shop_accepts(const std::string& tx_id, const std::string& shop_id) {
        try {
            pqxx::work txn(db_.connection());
            
            // Move to CONFIRMED status
            txn.exec_params(R"(
                UPDATE Global_Gifts
                SET status_code = $1,
                    shop_accepted_at = NOW()
                WHERE tx_id = $2 AND shop_id = $3
            )", static_cast<int>(OrderStatus::CONFIRMED), tx_id, shop_id);
            
            txn.commit();
            
            std::cout << "[BAKER] Order " << tx_id 
                      << " ACCEPTED by shop " << shop_id << std::endl;
            
            // TODO: Trigger payment capture via gateway
            // trigger_payment_capture(tx_id);
            
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "[BAKER] Accept error: " << e.what() << std::endl;
            return false;
        }
    }
    
    /**
     * Shop declines the order
     * Triggers: Re-routing search OR refund
     */
    bool shop_declines(const std::string& tx_id, const std::string& shop_id, const std::string& reason) {
        try {
            pqxx::work txn(db_.connection());
            
            txn.exec_params(R"(
                UPDATE Global_Gifts
                SET status_code = $1,
                    decline_reason = $2,
                    declined_at = NOW()
                WHERE tx_id = $3 AND shop_id = $4
            )", static_cast<int>(OrderStatus::DECLINED), reason, tx_id, shop_id);
            
            txn.commit();
            
            std::cout << "[BAKER] Order " << tx_id 
                      << " DECLINED by shop " << shop_id 
                      << " (reason: " << reason << ")" << std::endl;
            
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "[BAKER] Decline error: " << e.what() << std::endl;
            return false;
        }
    }
};

// =============================================================================
// ORCHESTRATOR (Main Controller)
// =============================================================================

class Orchestrator {
private:
    Database db_;
    ReroutingEngine rerouter_;
    BakersProtocol baker_;
    
public:
    Orchestrator(const std::string& db_connection)
        : db_(db_connection)
        , rerouter_(db_)
        , baker_(db_)
    {}
    
    /**
     * Process order state changes
     * Main event loop handler
     */
    void process_order(const Order& order) {
        std::cout << "[ORCHESTRATOR] Processing order " << order.tx_id 
                  << " (status: " << order.status_code << ")" << std::endl;
        
        // Handle Status 910 (Declined) with auto-reroute
        if (order.status_code == static_cast<int>(OrderStatus::DECLINED) 
            && order.auto_reroute) {
            
            std::cout << "[ORCHESTRATOR] Initiating re-route search..." << std::endl;
            
            // Calculate original distance (would come from order data)
            double original_distance = 2.5; // TODO: Get from order
            
            auto result = rerouter_.find_alternative(order, original_distance);
            
            if (result.found) {
                // Shadow lock the alternative shop's inventory
                if (rerouter_.shadow_lock_inventory(result.alternative_shop_id, order.tx_id)) {
                    // Update order to ALT_FOUND (106)
                    rerouter_.update_order_reroute(order.tx_id, result);
                    
                    std::cout << "[ORCHESTRATOR] Re-route SUCCESS: " 
                              << result.shop_name 
                              << " (diff: " << result.distance_diff_km << "km)"
                              << " in " << result.search_time.count() << "µs" << std::endl;
                    
                    // TODO: Trigger push notification via gateway
                    // gateway::push::send_reroute_notification(order.tx_id);
                }
            } else {
                std::cout << "[ORCHESTRATOR] No alternative found within 5km" << std::endl;
                // TODO: Trigger refund flow
            }
        }
    }
    
    /**
     * Handle new order placement
     */
    void handle_new_order(const std::string& tx_id, const std::string& product_id) {
        if (baker_.requires_acceptance(product_id)) {
            baker_.set_awaiting_acceptance(tx_id);
        }
        // Standard flow continues in Python gateway
    }
};

} // namespace kithly

// =============================================================================
// MAIN (Development/Testing Entry Point)
// =============================================================================

int main() {
    std::cout << "KithLy Orchestrator v1.0 (Phase V)" << std::endl;
    std::cout << "===================================" << std::endl;
    
    // Connection string would come from environment
    const char* db_conn = std::getenv("KITHLY_DB_URL");
    if (!db_conn) {
        db_conn = "postgresql://localhost/kithly";
    }
    
    try {
        kithly::Orchestrator orchestrator(db_conn);
        
        // Example: Process a declined order
        kithly::Order test_order{
            .tx_id = "test-tx-001",
            .shop_id = "shop-001",
            .recipient_id = "recipient-001",
            .category_id = "flowers",
            .status_code = 910,  // DECLINED
            .recipient_lat = -15.3875,
            .recipient_lon = 28.3228,
            .auto_reroute = true,
            .original_shop_id = "shop-001",
            .alternative_shop_id = ""
        };
        
        orchestrator.process_order(test_order);
        
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
