import asyncio
from sqlalchemy import text
from services.database import engine

async def run_migration():
    print("Beginning Escrow Protocol DB Migration...")
    async with engine.begin() as conn:
        print("1. Creating EscrowStatus ENUM type...")
        try:
            await conn.execute(text("CREATE TYPE escrowstatus AS ENUM ('INITIATED', 'ESCROW_LOCKED', 'IN_TRANSIT', 'PENDING_HANDSHAKE', 'FUNDS_RELEASED');"))
        except Exception as e:
            print(f"Type might already exist: {e}")

        print("2. Altering status column to use ENUM securely...")
        # Since the column previously held integers, we must cast or map them manually. 
        # Using a CASE statement translates old state codes to our strong ENUM.
        await conn.execute(text("""
            ALTER TABLE global_gifts 
            ALTER COLUMN status DROP DEFAULT,
            ALTER COLUMN status TYPE escrowstatus 
            USING CASE 
                WHEN status=100 THEN 'INITIATED'::escrowstatus
                WHEN status=200 THEN 'ESCROW_LOCKED'::escrowstatus
                WHEN status=250 THEN 'FUNDS_RELEASED'::escrowstatus
                WHEN status=300 THEN 'IN_TRANSIT'::escrowstatus
                ELSE 'INITIATED'::escrowstatus 
            END,
            ALTER COLUMN status SET DEFAULT 'INITIATED'::escrowstatus;
        """))

        print("3. Adding handshake_jwt and escrow_released_at columns...")
        await conn.execute(text("ALTER TABLE global_gifts ADD COLUMN IF NOT EXISTS handshake_jwt VARCHAR(500);"))
        await conn.execute(text("ALTER TABLE global_gifts ADD COLUMN IF NOT EXISTS escrow_released_at TIMESTAMPTZ;"))

    print("Migration complete. The Escrow Protocol is live.")

if __name__ == "__main__":
    asyncio.run(run_migration())
