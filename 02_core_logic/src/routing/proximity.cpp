/**
 * =============================================================================
 * KithLy Global Protocol - LAYER 2: THE BRAIN (C++23)
 * routing/proximity.cpp - Shop-Swap / Proximity Algorithms
 * =============================================================================
 */

#include "../include/constants.h"
#include "../include/structs.h"
#include "../include/db_connector.h"

#include <cmath>
#include <algorithm>
#include <queue>

namespace kithly {
namespace routing {

// Earth radius in kilometers
constexpr double EARTH_RADIUS_KM = 6371.0;

/**
 * Calculate Haversine distance between two points
 */
double haversine_distance(const GeoPoint& a, const GeoPoint& b) {
    auto to_rad = [](double deg) { return deg * M_PI / 180.0; };
    
    double lat1 = to_rad(a.latitude);
    double lat2 = to_rad(b.latitude);
    double dlat = to_rad(b.latitude - a.latitude);
    double dlon = to_rad(b.longitude - a.longitude);
    
    double h = std::sin(dlat / 2) * std::sin(dlat / 2) +
               std::cos(lat1) * std::cos(lat2) *
               std::sin(dlon / 2) * std::sin(dlon / 2);
               
    double c = 2 * std::atan2(std::sqrt(h), std::sqrt(1 - h));
    
    return EARTH_RADIUS_KM * c;
}

// Implement GeoPoint::distance_km
double GeoPoint::distance_km(const GeoPoint& other) const {
    return haversine_distance(*this, other);
}

/**
 * Proximity Engine for shop discovery and shop-swap
 */
class ProximityEngine {
public:
    explicit ProximityEngine(std::shared_ptr<db::ShopRepository> shop_repo)
        : shop_repo_(shop_repo) {}

    /**
     * Find nearest shops to a location
     */
    Result<std::vector<NearbyShop>> find_nearest_shops(
        const GeoPoint& location,
        double radius_km = config::DEFAULT_RADIUS_KM,
        int limit = 10
    ) {
        return shop_repo_->find_nearby(location, radius_km, limit);
    }

    /**
     * Find alternative shops for shop-swap
     * Used when original shop is out of stock or unavailable
     */
    Result<std::vector<NearbyShop>> find_swap_candidates(
        const GeoPoint& receiver_location,
        const UUID& product_type_id,
        const UUID& original_shop_id,
        double radius_km = config::DEFAULT_RADIUS_KM * 2  // Wider radius for swap
    ) {
        auto candidates = shop_repo_->find_nearby_with_product(
            receiver_location, 
            product_type_id, 
            radius_km, 
            10
        );
        
        if (!candidates.success) {
            return candidates;
        }
        
        // Filter out original shop and sort by score
        std::vector<NearbyShop> filtered;
        for (const auto& shop : *candidates.value) {
            if (shop.shop.id != original_shop_id) {
                filtered.push_back(shop);
            }
        }
        
        // Sort by combined score (distance + confidence)
        std::sort(filtered.begin(), filtered.end(), [](const auto& a, const auto& b) {
            double score_a = a.distance_km * 0.6 + (1.0 - a.confidence_score) * 0.4;
            double score_b = b.distance_km * 0.6 + (1.0 - b.confidence_score) * 0.4;
            return score_a < score_b;
        });
        
        return Result<std::vector<NearbyShop>>::ok(std::move(filtered));
    }

    /**
     * Calculate optimal pickup route for a rider
     * Uses greedy nearest-neighbor heuristic
     */
    Result<std::vector<UUID>> optimize_pickup_route(
        const GeoPoint& rider_location,
        const std::vector<std::pair<UUID, GeoPoint>>& pickups
    ) {
        if (pickups.empty()) {
            return Result<std::vector<UUID>>::ok({});
        }
        
        std::vector<UUID> route;
        std::vector<bool> visited(pickups.size(), false);
        GeoPoint current = rider_location;
        
        for (size_t i = 0; i < pickups.size(); ++i) {
            double min_dist = std::numeric_limits<double>::max();
            size_t min_idx = 0;
            
            for (size_t j = 0; j < pickups.size(); ++j) {
                if (!visited[j]) {
                    double dist = current.distance_km(pickups[j].second);
                    if (dist < min_dist) {
                        min_dist = dist;
                        min_idx = j;
                    }
                }
            }
            
            visited[min_idx] = true;
            route.push_back(pickups[min_idx].first);
            current = pickups[min_idx].second;
        }
        
        return Result<std::vector<UUID>>::ok(std::move(route));
    }

    /**
     * Estimate delivery time based on distance and traffic
     */
    int estimate_delivery_minutes(
        const GeoPoint& from,
        const GeoPoint& to,
        double traffic_factor = 1.0  // 1.0 = normal, 2.0 = heavy traffic
    ) {
        double distance = from.distance_km(to);
        
        // Average speed assumptions (km/h)
        constexpr double AVG_SPEED_MOTORCYCLE = 25.0;  // Urban motorcycle
        constexpr double PICKUP_TIME_MINUTES = 5.0;
        
        double travel_time = (distance / AVG_SPEED_MOTORCYCLE) * 60.0 * traffic_factor;
        
        return static_cast<int>(std::ceil(travel_time + PICKUP_TIME_MINUTES));
    }

private:
    std::shared_ptr<db::ShopRepository> shop_repo_;
};

} // namespace routing
} // namespace kithly
