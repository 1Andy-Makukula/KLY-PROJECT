-- ============================================================================
-- KithLy Global Protocol - SEED DATA
-- 001_initial_stock.sql - Mock Shops & Products in Lusaka
-- ============================================================================

-- Insert 3 Shops in Lusaka
INSERT INTO Shops (shop_id, name, address, city, latitude, longitude, location) VALUES
(
    'a1b2c3d4-e5f6-7890-abcd-111111111111',
    'Shoprite Manda Hill',
    'Manda Hill Shopping Mall, Great East Road',
    'Lusaka',
    -15.3982,
    28.3228,
    ST_SetSRID(ST_MakePoint(28.3228, -15.3982), 4326)
),
(
    'a1b2c3d4-e5f6-7890-abcd-222222222222',
    'Chilenje Hardware Store',
    'Plot 45, Chilenje South',
    'Lusaka',
    -15.4321,
    28.2876,
    ST_SetSRID(ST_MakePoint(28.2876, -15.4321), 4326)
),
(
    'a1b2c3d4-e5f6-7890-abcd-333333333333',
    'Rhodes Park Pharmacy',
    '12 Independence Avenue, Rhodes Park',
    'Lusaka',
    -15.4012,
    28.2945,
    ST_SetSRID(ST_MakePoint(28.2945, -15.4012), 4326)
);

-- Insert 5 Products linked to the Shops
INSERT INTO Product_Catalog (sku_id, shop_id, name, price_zmw, stock_level) VALUES
-- Shoprite Manda Hill products
('SKU-SHOP-001', 'a1b2c3d4-e5f6-7890-abcd-111111111111', 'Coca-Cola 2L', 45.00, 150),
('SKU-SHOP-002', 'a1b2c3d4-e5f6-7890-abcd-111111111111', 'White Bread Loaf', 32.00, 80),

-- Chilenje Hardware product
('SKU-HW-001', 'a1b2c3d4-e5f6-7890-abcd-222222222222', 'Hammer 500g', 85.00, 25),

-- Rhodes Park Pharmacy products
('SKU-PHARM-001', 'a1b2c3d4-e5f6-7890-abcd-333333333333', 'Paracetamol 500mg (20 tablets)', 28.00, 200),
('SKU-PHARM-002', 'a1b2c3d4-e5f6-7890-abcd-333333333333', 'Vitamin C 1000mg (30 tablets)', 95.00, 45);
