/**
 * =============================================================================
 * KithLy Global Protocol - DATA STRUCTURES
 * structs.h - Product, Shop, and Evidence definitions
 * =============================================================================
 */

#pragma once

#include <string>
#include <ctime>
#include <nlohmann/json.hpp>

namespace Kithly {

/**
 * Shop - matches Shops table in SQL
 */
struct Shop {
    std::string shop_id;      // UUID
    std::string name;
    std::string address;
    std::string city;
    double latitude;
    double longitude;
    bool is_active;
    std::time_t created_at;
};

/**
 * Product - matches Product_Catalog table in SQL
 */
struct Product {
    std::string sku_id;       // VARCHAR(50)
    std::string shop_id;      // UUID reference to Shop
    std::string name;
    double price_zmw;         // NUMERIC(10,2)
    int stock_level;
    std::time_t last_updated;
};

/**
 * Evidence - matches Delivery_Proofs table in SQL
 */
struct Evidence {
    std::string proof_id;     // UUID
    std::string tx_id;        // UUID reference to Global_Gifts
    
    // The Evidence
    std::string proof_type;   // "photo", "signature", "receipt"
    std::string file_url;
    int file_size;
    std::string mime_type;
    
    // Integrity (SHA-256 hash - 64 hex chars)
    std::string receipt_hash;
    
    // Metadata
    std::time_t captured_at;
    double latitude;
    double longitude;
    std::string device_info;  // JSON string
    
    // Audit
    std::string uploaded_by;  // UUID
    std::time_t created_at;
};

/**
 * GiftPayload - JSON payload from Redis Ingestion Queue
 */
struct GiftPayload {
    std::string tx_id;
    std::string idempotency_key;
    std::string receiver_phone;
    std::string shop_id;
    std::string product_id;
    int quantity;
};

NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(GiftPayload, tx_id, idempotency_key, receiver_phone, shop_id, product_id, quantity)

} // namespace Kithly
