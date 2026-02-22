/**
 * =============================================================================
 * KithLy Global Protocol - LAYER 2: THE BRAIN (C++17)
 * main.cpp - Event-driven Worker Node (Redis Queue Drainer)
 * =============================================================================
 */

#include "include/constants.h"
#include "include/structs.h"
#include "include/db_connector.h"
#include "include/orchestrator.h"

#include <sw/redis++/redis++.h>
#include <iostream>
#include <memory>
#include <string>
#include <csignal>
#include <atomic>
#include <chrono>
#include <thread>
#include <optional>

namespace kithly {

// Global shutdown flag
std::atomic<bool> g_shutdown{false};

void signal_handler(int signal) {
    std::cout << "\n[KITHLY] Received signal " << signal << ", initiating graceful shutdown..." << std::endl;
    g_shutdown = true;
}

/**
 * The KithLy Core Worker
 * High-performance event-driven engine for draining Redis ingestion queues
 */
class KithLyWorker {
public:
    KithLyWorker(const db::DbConfig& db_config) {
        // Initialize connection pool
        pool_ = std::make_shared<db::ConnectionPool>(db_config);
        
        // Initialize repositories
        gift_repo_ = std::make_shared<db::GiftRepository>(pool_);
        shop_repo_ = std::make_shared<db::ShopRepository>(pool_);
        evidence_repo_ = std::make_shared<db::EvidenceRepository>(pool_);
        
        std::cout << "[KITHLY] Worker initialized with " << db_config.pool_size << " DB connections" << std::endl;
    }

    void run() {
        std::cout << "[KITHLY] ============================================" << std::endl;
        std::cout << "[KITHLY]    KithLy Global Protocol - C++ Worker Node" << std::endl;
        std::cout << "[KITHLY] ============================================" << std::endl;
        std::cout << "[KITHLY] Connecting to Redis at tcp://127.0.0.1:6379" << std::endl;
        std::cout << "[KITHLY] Queue: kithly:ingestion:gifts" << std::endl;
        std::cout << "[KITHLY] ============================================" << std::endl;
        
        // Initialize Redis Client
        auto redis = sw::redis::Redis("tcp://127.0.0.1:6379");

        // Event-driven Drain Loop
        while (!g_shutdown) {
            try {
                // Blocking pop with a 0 timeout (wait forever)
                // Note: We use brpop which blocks the thread until an item arrives
                auto result = redis.brpop("kithly:ingestion:gifts", 0);
                
                if (result) {
                    // result is a std::optional<std::pair<std::string, std::string>>
                    // result->first is the queue name, result->second is the JSON payload
                    auto& payload = result->second;
                    
                    std::cout << "\n📦 C++ Worker Pulled Job from Queue" << std::endl;
                    std::cout << "Raw Payload: " << payload << std::endl;
                    
                    try {
                        Kithly::Orchestrator::process_gift_job(payload);
                    } catch (const std::exception& e) {
                        std::cerr << "[KITHLY ERROR] Failed to process payload: " << e.what() << std::endl;
                    }
                }

            } catch (const sw::redis::TimeoutError& e) {
                // Ignore timeout and continue if we had a non-zero timeout
                continue;
            } catch (const sw::redis::Error& e) {
                // Handle Redis disconnections/errors gracefully
                std::cerr << "[KITHLY ERROR] Redis exception: " << e.what() << std::endl;
                std::cerr << "Attempting to reconnect in 3 seconds..." << std::endl;
                std::this_thread::sleep_for(std::chrono::seconds(3));
                
                // (Re)Initialize Redis Client on disconnect
                try {
                    redis = sw::redis::Redis("tcp://127.0.0.1:6379");
                } catch (const std::exception& reconnect_e) {
                    std::cerr << "[KITHLY ERROR] Reconnect failed: " << reconnect_e.what() << std::endl;
                }
            } catch (const std::exception& e) {
                // Catch standard exceptions to prevent full crash
                std::cerr << "[KITHLY FATAL] Worker exception: " << e.what() << std::endl;
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        }
        
        std::cout << "[KITHLY] Shutdown complete." << std::endl;
    }

private:
    std::shared_ptr<db::ConnectionPool> pool_;
    std::shared_ptr<db::GiftRepository> gift_repo_;
    std::shared_ptr<db::ShopRepository> shop_repo_;
    std::shared_ptr<db::EvidenceRepository> evidence_repo_;
};

} // namespace kithly

int main(int argc, char* argv[]) {
    std::cout << "KithLy Global Protocol - Core Engine v1.0.0" << std::endl;
    std::cout << "Built with C++17 for maximum performance" << std::endl;
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
    
    try {
        kithly::KithLyWorker worker(db_config);
        worker.run();
    } catch (const std::exception& e) {
        std::cerr << "[FATAL] " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
