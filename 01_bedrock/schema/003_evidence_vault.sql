-- ============================================================================
-- KithLy Global Protocol - EVIDENCE VAULT (Phase III + ZRA VSDC)
-- 003_evidence_vault.sql - Delivery Proofs with ZRA Fiscal Compliance
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Delivery Proofs Table (ZRA VSDC Compliant)
CREATE TABLE Delivery_Proofs (
    proof_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tx_id        UUID NOT NULL REFERENCES Global_Gifts(tx_id),
    
    -- ZRA Mandatory Data
    tpin         VARCHAR(20) NOT NULL,
    bhf_id       VARCHAR(10) NOT NULL,  -- Branch ID
    vsdc_serial  VARCHAR(50),
    
    -- Evidence Data
    proof_type   VARCHAR(50) NOT NULL,
    photo_url    TEXT NOT NULL,
    receipt_hash CHAR(64) UNIQUE NOT NULL,  -- SHA-256
    kithly_receipt_url TEXT,                 -- KithLy branded PDF receipt
    
    -- AI Validation Results
    vision_confidence_score FLOAT DEFAULT 0.0,
    extracted_date    VARCHAR(20),
    extracted_amount  NUMERIC(12, 2),
    
    -- ZRA VSDC Response
    zra_result_code   VARCHAR(10),      -- '000' = success, '001' = partial
    zra_last_req_dt   VARCHAR(20),      -- Format: YYYYMMDDHHMMSS
    vsdc_response_json JSONB,
    
    -- Metadata
    latitude     NUMERIC(10, 8),
    longitude    NUMERIC(11, 8),
    device_info  JSONB,
    
    -- Audit
    uploaded_by  UUID,
    uploaded_at  TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(tx_id, proof_type)
);

-- Sync Request Queue (for ZRA retry with exponential backoff)
CREATE TABLE ZRA_Sync_Queue (
    sync_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tx_id        UUID NOT NULL REFERENCES Global_Gifts(tx_id),
    proof_id     UUID REFERENCES Delivery_Proofs(proof_id),
    
    endpoint     VARCHAR(100) NOT NULL,
    payload_json JSONB NOT NULL,
    
    -- Retry tracking
    attempt_count INT DEFAULT 0,
    max_attempts  INT DEFAULT 5,
    next_retry_at TIMESTAMPTZ,
    last_error    TEXT,
    
    -- Status
    status       VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, SUCCESS, FAILED
    
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_proofs_tx ON Delivery_Proofs(tx_id);
CREATE INDEX idx_proofs_hash ON Delivery_Proofs(receipt_hash);
CREATE INDEX idx_proofs_tpin ON Delivery_Proofs(tpin);
CREATE INDEX idx_sync_status ON ZRA_Sync_Queue(status) WHERE status = 'PENDING';
CREATE INDEX idx_sync_retry ON ZRA_Sync_Queue(next_retry_at) WHERE status = 'PENDING';

-- ============================================================================
-- THE "AERONAUTICAL" INTERLOCK (updated for ZRA)
-- Prevents status 400 without BOTH delivery proof AND successful ZRA result
-- ============================================================================

CREATE OR REPLACE FUNCTION check_proof_before_complete()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status_code = 400 THEN
        -- Check proof exists
        IF NOT EXISTS (SELECT 1 FROM Delivery_Proofs WHERE tx_id = NEW.tx_id) THEN
            RAISE EXCEPTION 'Cannot complete transaction without delivery proof.';
        END IF;
        
        -- Check ZRA fiscalization success
        IF NOT EXISTS (
            SELECT 1 FROM Delivery_Proofs 
            WHERE tx_id = NEW.tx_id 
            AND zra_result_code IN ('000', '001')
        ) THEN
            RAISE EXCEPTION 'Cannot complete transaction without ZRA fiscalization.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_proof
    BEFORE UPDATE ON Global_Gifts
    FOR EACH ROW
    EXECUTE FUNCTION check_proof_before_complete();

-- Helper: SHA-256 hash function
CREATE OR REPLACE FUNCTION hash_evidence(content BYTEA)
RETURNS CHAR(64) AS $$
BEGIN
    RETURN encode(digest(content, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
