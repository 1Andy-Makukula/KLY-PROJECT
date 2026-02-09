/**
 * =============================================================================
 * KithLy Global Protocol - LAYER 2: THE BRAIN (C++23)
 * main.cpp - Heartbeat (High-speed gRPC Server)
 * =============================================================================
 */

#include "include/constants.h"
#include "include/structs.h"
#include "include/db_connector.h"

#include <iostream>
#include <memory>
#include <string>
#include <csignal>
#include <atomic>

namespace kithly {

// Global shutdown flag
std::atomic<bool> g_shutdown{false};

void signal_handler(int signal) {
    std::cout << "\n[KITHLY] Received signal " << signal << ", initiating graceful shutdown..." << std::endl;
    g_shutdown = true;
}

/**
 * The KithLy Core Server
 * High-performance engine for gift transaction processing
 */
class KithLyCore {
public:
    KithLyCore(const db::DbConfig& db_config, int port)
        : port_(port) 
    {
        // Initialize connection pool
        pool_ = std::make_shared<db::ConnectionPool>(db_config);
        
        // Initialize repositories
        gift_repo_ = std::make_shared<db::GiftRepository>(pool_);
        shop_repo_ = std::make_shared<db::ShopRepository>(pool_);
        evidence_repo_ = std::make_shared<db::EvidenceRepository>(pool_);
        
        std::cout << "[KITHLY] Core initialized with " << db_config.pool_size << " DB connections" << std::endl;
    }

    void run() {
        std::cout << "[KITHLY] ============================================" << std::endl;
        std::cout << "[KITHLY]    KithLy Global Protocol - Core Engine" << std::endl;
        std::cout << "[KITHLY] ============================================" << std::endl;
        std::cout << "[KITHLY] Starting server on port " << port_ << std::endl;
        std::cout << "[KITHLY] Status codes: 100-900 Protocol Active" << std::endl;
        std::cout << "[KITHLY] Idempotency: Enabled (" << config::IDEMPOTENCY_WINDOW_HOURS << "h window)" << std::endl;
        std::cout << "[KITHLY] Proximity: " << config::DEFAULT_RADIUS_KM << "km default radius" << std::endl;
        std::cout << "[KITHLY] ============================================" << std::endl;
        
        // Heartbeat loop
        while (!g_shutdown) {
            heartbeat();
            std::this_thread::sleep_for(std::chrono::seconds(5));
        }
        
        std::cout << "[KITHLY] Shutdown complete." << std::endl;
    }

private:
    int port_;
    std::shared_ptr<db::ConnectionPool> pool_;
    std::shared_ptr<db::GiftRepository> gift_repo_;
    std::shared_ptr<db::ShopRepository> shop_repo_;
    std::shared_ptr<db::EvidenceRepository> evidence_repo_;
    
    uint64_t heartbeat_count_ = 0;
    
    void heartbeat() {
        ++heartbeat_count_;
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        
        std::cout << "[HEARTBEAT #" << heartbeat_count_ << "] "
                  << std::ctime(&time_t)
                  << "  DB Pool: " << pool_->available() << " available, " 
                  << pool_->in_use() << " in use" << std::endl;
    }
};

} // namespace kithly

int main(int argc, char* argv[]) {
    std::cout << "KithLy Global Protocol - Core Engine v1.0.0" << std::endl;
    std::cout << "Built with C++23 for maximum performance" << std::endl;
    std::cout << std::endl;
    
    // Setup signal handlers
    std::signal(SIGINT, kithly::signal_handler);
    std::signal(SIGTERM, kithly::signal_handler);
    
    // Parse configuration (from env or args)
    kithly::db::DbConfig db_config;
    db_config.host = std::getenv("KITHLY_DB_HOST") ? std::getenv("KITHLY_DB_HOST") : "localhost";
    db_config.port = std::getenv("KITHLY_DB_PORT") ? std::stoi(std::getenv("KITHLY_DB_PORT")) : 5432;
    db_config.database = std::getenv("KITHLY_DB_NAME") ? std::getenv("KITHLY_DB_NAME") : "kithly";
    db_config.user = std::getenv("KITHLY_DB_USER") ? std::getenv("KITHLY_DB_USER") : "kithly_app";
    db_config.password = std::getenv("KITHLY_DB_PASSWORD") ? std::getenv("KITHLY_DB_PASSWORD") : "";
    db_config.pool_size = std::getenv("KITHLY_DB_POOL_SIZE") ? std::stoi(std::getenv("KITHLY_DB_POOL_SIZE")) : 10;
    
    int port = std::getenv("KITHLY_PORT") ? std::stoi(std::getenv("KITHLY_PORT")) : 50051;
    
    try {
        kithly::KithLyCore core(db_config, port);
        core.run();
    } catch (const std::exception& e) {
        std::cerr << "[FATAL] " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
