/**
 * =============================================================================
 * KithLy Global Protocol - THE REROUTER
 * routing.cpp - Haversine Formula for nearest shop lookup
 * =============================================================================
 */

#include "structs.h"
#include "db_connector.h"
#include <cmath>
#include <vector>
#include <algorithm>
#include <libpq-fe.h>
#include <iostream>

namespace Kithly {

// Earth radius in kilometers
constexpr double EARTH_RADIUS_KM = 6371.0;
constexpr double PI = 3.14159265358979323846;

/**
 * Convert degrees to radians
 */
inline double to_radians(double degrees) {
    return degrees * PI / 180.0;
}

/**
 * Haversine Formula - Calculate distance between two points on Earth
 * Returns distance in kilometers
 */
double haversine_distance(double lat1, double lon1, double lat2, double lon2) {
    double dlat = to_radians(lat2 - lat1);
    double dlon = to_radians(lon2 - lon1);
    
    double a = std::sin(dlat / 2) * std::sin(dlat / 2) +
               std::cos(to_radians(lat1)) * std::cos(to_radians(lat2)) *
               std::sin(dlon / 2) * std::sin(dlon / 2);
    
    double c = 2 * std::atan2(std::sqrt(a), std::sqrt(1 - a));
    
    return EARTH_RADIUS_KM * c;
}

/**
 * Shop with distance for sorting
 */
struct ShopDistance {
    std::string shop_id;
    std::string name;
    double distance_km;
};

/**
 * Find the nearest alternative shop excluding the failed shop
 * Uses Haversine formula for accurate geospatial distance
 */
std::string find_nearest_shop(
    const std::string& failed_shop_id,
    double origin_lat,
    double origin_lon,
    PGconn* conn
) {
    // Query all active shops except the failed one
    const char* query = R"(
        SELECT shop_id, name, latitude, longitude 
        FROM Shops 
        WHERE shop_id != $1 AND is_active = true
    )";
    
    const char* params[1] = { failed_shop_id.c_str() };
    
    PGresult* res = PQexecParams(conn, query, 1, nullptr, params, nullptr, nullptr, 0);
    
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        std::cerr << "[ROUTING] Query failed: " << PQerrorMessage(conn) << std::endl;
        PQclear(res);
        return "";
    }
    
    std::vector<ShopDistance> shops;
    int rows = PQntuples(res);
    
    for (int i = 0; i < rows; ++i) {
        ShopDistance sd;
        sd.shop_id = PQgetvalue(res, i, 0);
        sd.name = PQgetvalue(res, i, 1);
        double lat = std::stod(PQgetvalue(res, i, 2));
        double lon = std::stod(PQgetvalue(res, i, 3));
        
        sd.distance_km = haversine_distance(origin_lat, origin_lon, lat, lon);
        shops.push_back(sd);
    }
    
    PQclear(res);
    
    if (shops.empty()) {
        std::cerr << "[ROUTING] No alternative shops found" << std::endl;
        return "";
    }
    
    // Sort by distance and return nearest
    std::sort(shops.begin(), shops.end(), 
        [](const ShopDistance& a, const ShopDistance& b) {
            return a.distance_km < b.distance_km;
        });
    
    std::cout << "[ROUTING] Rerouting to: " << shops[0].name 
              << " (" << shops[0].distance_km << " km away)" << std::endl;
    
    return shops[0].shop_id;
}

} // namespace Kithly
