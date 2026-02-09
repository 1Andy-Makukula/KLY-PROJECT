-- ============================================================================
-- KithLy Global Protocol - OPERATING HOURS
-- 004_operating_hours.sql - Shop Open/Close Times
-- ============================================================================

CREATE TABLE Operating_Hours (
    id          SERIAL PRIMARY KEY,
    shop_id     UUID REFERENCES Shops(shop_id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday
    open_time   TIME NOT NULL,
    close_time  TIME NOT NULL,
    
    UNIQUE(shop_id, day_of_week)
);

-- Index for fast lookups
CREATE INDEX idx_operating_hours_shop ON Operating_Hours(shop_id);
CREATE INDEX idx_operating_hours_day ON Operating_Hours(day_of_week);

-- Function to check if shop is open now
CREATE OR REPLACE FUNCTION is_shop_open(p_shop_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_day INT;
    current_time TIME;
    is_open BOOLEAN;
BEGIN
    current_day := EXTRACT(DOW FROM NOW());
    current_time := NOW()::TIME;
    
    SELECT EXISTS(
        SELECT 1 FROM Operating_Hours
        WHERE shop_id = p_shop_id
          AND day_of_week = current_day
          AND current_time BETWEEN open_time AND close_time
    ) INTO is_open;
    
    RETURN is_open;
END;
$$ LANGUAGE plpgsql;
