-- =============================================================================
-- KithLy Global Protocol - PHASE V: GRAND UNIFICATION
-- 006_grand_unification.sql - Schema Expansion for Intelligence Layer
-- =============================================================================
--
-- This migration adds:
-- 1. Shop Tiers & Performance Analytics
-- 2. Baker's Protocol (Made-to-Order Products)
-- 3. Smart Re-routing Infrastructure
-- 4. Wishlists
--
-- Run: psql -d kithly -f 006_grand_unification.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. SHOP TIERS & ANALYTICS
-- =============================================================================
-- Tiered system for shop classification based on performance

-- Add tier column (sandbox -> independent -> verified -> select)
ALTER TABLE Shops 
ADD COLUMN IF NOT EXISTS tier VARCHAR(20) DEFAULT 'sandbox';

-- Add performance score (0.00 - 100.00)
ALTER TABLE Shops 
ADD COLUMN IF NOT EXISTS performance_score DECIMAL(5,2) DEFAULT 0.00;

-- Add constraints
ALTER TABLE Shops 
ADD CONSTRAINT valid_tier 
CHECK (tier IN ('sandbox', 'independent', 'verified', 'select'));

ALTER TABLE Shops 
ADD CONSTRAINT valid_performance_score 
CHECK (performance_score >= 0 AND performance_score <= 100);

-- Index for tier-based queries
CREATE INDEX IF NOT EXISTS idx_shops_tier ON Shops(tier);
CREATE INDEX IF NOT EXISTS idx_shops_performance ON Shops(performance_score DESC);

COMMENT ON COLUMN Shops.tier IS 
'Shop classification: sandbox (new), independent (active), verified (ZRA compliant), select (premium)';

COMMENT ON COLUMN Shops.performance_score IS 
'Calculated score (0-100) based on completion rate, ZRA compliance, and customer ratings';


-- =============================================================================
-- 2. BAKER''S PROTOCOL (Custom/Made-to-Order Products)
-- =============================================================================
-- Products that require shop acceptance before order confirmation

ALTER TABLE Products 
ADD COLUMN IF NOT EXISTS is_made_to_order BOOLEAN DEFAULT FALSE;

-- Lead time for made-to-order items (in hours)
ALTER TABLE Products 
ADD COLUMN IF NOT EXISTS lead_time_hours INTEGER DEFAULT NULL;

COMMENT ON COLUMN Products.is_made_to_order IS 
'If TRUE, shop must accept order before funds are captured (Baker''s Protocol)';

COMMENT ON COLUMN Products.lead_time_hours IS 
'Estimated preparation time for made-to-order items (nullable for stock items)';


-- =============================================================================
-- 3. SMART RE-ROUTING INFRASTRUCTURE
-- =============================================================================
-- Enable automatic shop failover within delivery radius

-- Original shop that was first matched
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS original_shop_id UUID;

-- Alternative shop found via re-routing
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS alternative_shop_id UUID;

-- Distance difference (e.g., "+1.2km" or "-0.5km")
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS re_route_distance_diff VARCHAR(20);

-- Delivery zone classification
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS delivery_zone VARCHAR(10);

-- Calculated delivery fee based on zone
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10,2);

-- Auto-reroute preference
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS auto_reroute BOOLEAN DEFAULT TRUE;

-- Timestamp when re-route was found
ALTER TABLE Global_Gifts 
ADD COLUMN IF NOT EXISTS rerouted_at TIMESTAMP;

-- Add foreign key constraints
ALTER TABLE Global_Gifts 
ADD CONSTRAINT fk_original_shop 
FOREIGN KEY (original_shop_id) REFERENCES Shops(shop_id) ON DELETE SET NULL;

ALTER TABLE Global_Gifts 
ADD CONSTRAINT fk_alternative_shop 
FOREIGN KEY (alternative_shop_id) REFERENCES Shops(shop_id) ON DELETE SET NULL;

-- Zone constraint
ALTER TABLE Global_Gifts 
ADD CONSTRAINT valid_delivery_zone 
CHECK (delivery_zone IS NULL OR delivery_zone IN ('A', 'B', 'C'));

-- Index for re-routing queries
CREATE INDEX IF NOT EXISTS idx_gifts_reroute ON Global_Gifts(status_code) 
WHERE status_code IN (910, 106);

CREATE INDEX IF NOT EXISTS idx_gifts_zone ON Global_Gifts(delivery_zone);

COMMENT ON COLUMN Global_Gifts.original_shop_id IS 
'First shop that was matched (before any re-routing)';

COMMENT ON COLUMN Global_Gifts.alternative_shop_id IS 
'Replacement shop found via PostGIS proximity search';

COMMENT ON COLUMN Global_Gifts.delivery_zone IS 
'Zone A (0-5km, K50), Zone B (5-15km, K100), Zone C (15km+, K220)';


-- =============================================================================
-- 4. WISHLISTS
-- =============================================================================
-- User product wishlists for future purchase

CREATE TABLE IF NOT EXISTS Wishlists (
    wishlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    product_id UUID NOT NULL,
    shop_id UUID,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Prevent duplicate entries
    UNIQUE(user_id, product_id)
);

-- Foreign keys
ALTER TABLE Wishlists
ADD CONSTRAINT fk_wishlist_product 
FOREIGN KEY (product_id) REFERENCES Products(sku_id) ON DELETE CASCADE;

ALTER TABLE Wishlists
ADD CONSTRAINT fk_wishlist_shop 
FOREIGN KEY (shop_id) REFERENCES Shops(shop_id) ON DELETE SET NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wishlists_user ON Wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product ON Wishlists(product_id);

COMMENT ON TABLE Wishlists IS 
'User wishlists for tracking products of interest';


-- =============================================================================
-- 5. NEW STATUS CODES (update reference table if exists)
-- =============================================================================
-- 106: ALT_FOUND (Alternative shop found via re-routing)
-- 110: AWAITING_SHOP_ACCEPTANCE (Baker's Protocol - pending shop approval)
-- 910: DECLINED (Shop declined order)

-- Create or update status reference if table exists
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'status_codes') THEN
        INSERT INTO status_codes (code, name, description) VALUES 
            (106, 'ALT_FOUND', 'Alternative shop found via re-routing'),
            (110, 'AWAITING_SHOP_ACCEPTANCE', 'Baker''s Protocol: Awaiting shop acceptance'),
            (910, 'DECLINED', 'Shop declined the order')
        ON CONFLICT (code) DO NOTHING;
    END IF;
END $$;


COMMIT;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- Run these to verify migration success:

-- Check new columns on Shops
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'shops' AND column_name IN ('tier', 'performance_score');

-- Check new columns on Products
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'products' AND column_name = 'is_made_to_order';

-- Check new columns on Global_Gifts
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'global_gifts' AND column_name LIKE '%shop_id%';

-- Check Wishlists table
-- SELECT * FROM information_schema.tables WHERE table_name = 'wishlists';
