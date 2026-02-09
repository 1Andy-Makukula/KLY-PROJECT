-- ============================================================================
-- KithLy Global Protocol - THE FIRST BRICK
-- 001_initial_ledger.sql - Global Gifts Ledger
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- The Global Gifts Table - The Foundation
CREATE TABLE IF NOT EXISTS Global_Gifts (
    tx_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idempotency_key TEXT UNIQUE NOT NULL,
    sku_id          VARCHAR(100) NOT NULL,
    amount_zmw      NUMERIC(12, 2) NOT NULL,
    status_code     INT NOT NULL DEFAULT 100,
    
    -- Currency Oracle Fields (Phase V)
    final_collected_gbp  NUMERIC(12, 2),      -- Final GBP amount after all fees
    final_collected_usd  NUMERIC(12, 2),      -- Final USD amount after all fees  
    fx_rate_applied      NUMERIC(12, 6),      -- Exchange rate used
    volatility_buffer    BOOLEAN DEFAULT TRUE, -- Was 1.5% buffer applied
    stripe_payment_ref   VARCHAR(100),         -- Stripe PaymentIntent ID
    
    -- Proof-of-Collection Fields (Phase III-V)
    collection_token     VARCHAR(12),          -- 10-digit code: KT-XXXX-XX
    collection_qr_url    TEXT,                 -- QR code image URL
    expiry_timestamp     TIMESTAMPTZ,          -- 48-hour escrow deadline
    is_settled           BOOLEAN DEFAULT FALSE, -- Shop has been paid
    flutterwave_ref      VARCHAR(100),          -- Flutterwave disbursement ID
    
    -- Timestamps
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast status queries
CREATE INDEX idx_global_gifts_status ON Global_Gifts(status_code);
CREATE INDEX idx_global_gifts_idempotency ON Global_Gifts(idempotency_key);

-- Trigger to auto-update timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_global_gifts_updated
    BEFORE UPDATE ON Global_Gifts
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();
