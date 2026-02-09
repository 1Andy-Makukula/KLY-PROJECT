-- ============================================================================
-- KithLy Global Protocol - INVENTORY ENGINE
-- 002_proximity_graph.sql - Shops & Product Catalog
-- ============================================================================

-- Enable PostGIS for location queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Legal Entity Types
CREATE TYPE legal_entity_type AS ENUM ('sole_prop', 'ltd', 'partnership');
CREATE TYPE settlement_type AS ENUM ('mobile_money', 'bank');

-- Shops Table (Enterprise Onboarding)
CREATE TABLE Shops (
    shop_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name         TEXT NOT NULL,
    address      TEXT,
    city         VARCHAR(100) DEFAULT 'Lusaka',
    latitude     NUMERIC(10, 8),
    longitude    NUMERIC(11, 8),
    location     GEOGRAPHY(POINT, 4326),
    
    -- Contact Info
    phone_number VARCHAR(15),
    email        VARCHAR(255),
    owner_name   TEXT,
    
    -- Legal Entity (Step 2)
    legal_type   legal_entity_type DEFAULT 'sole_prop',
    pacra_number VARCHAR(50),                    -- Patent & Companies Registration Agency
    nrc_id_url   TEXT,                           -- National Registration Card image URL
    
    -- Shop Profile (Step 3)
    shopfront_photo_url TEXT,
    description  TEXT,
    category     VARCHAR(100),
    
    -- ZRA Compliance (Step 2)
    tpin         VARCHAR(20),
    bhf_id       VARCHAR(10) DEFAULT '00',
    vsdc_serial  VARCHAR(50),
    zra_verified BOOLEAN DEFAULT FALSE,
    
    -- Financial Settlement (Step 4)
    settlement   settlement_type DEFAULT 'mobile_money',
    settlement_account_details JSONB,            -- Encrypted: {number, bank_name, branch}
    
    -- Onboarding Progress
    onboarding_stage INT DEFAULT 1 CHECK (onboarding_stage BETWEEN 1 AND 5),
    is_verified  BOOLEAN DEFAULT FALSE,
    admin_approval_status VARCHAR(20) DEFAULT 'pending' CHECK (admin_approval_status IN ('pending', 'approved', 'rejected')),
    admin_notes  TEXT,
    verified_at  TIMESTAMPTZ,
    verified_by  UUID,
    
    -- Audit
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Product Catalog Table
CREATE TABLE Product_Catalog (
    sku_id       VARCHAR(50) PRIMARY KEY,
    shop_id      UUID REFERENCES Shops(shop_id),
    name         TEXT NOT NULL,
    price_zmw    NUMERIC(10, 2) NOT NULL,
    stock_level  INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_shops_city ON Shops(city);
CREATE INDEX idx_shops_location ON Shops USING GIST(location);
CREATE INDEX idx_product_shop ON Product_Catalog(shop_id);
CREATE INDEX idx_product_stock ON Product_Catalog(stock_level) WHERE stock_level > 0;
