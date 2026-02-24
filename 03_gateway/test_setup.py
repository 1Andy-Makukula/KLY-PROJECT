import asyncio
from services.database import engine
from sqlalchemy import text
from datetime import datetime

async def setup_test_tx():
    async with engine.begin() as conn:
        result = await conn.execute(text("SELECT tx_ref FROM global_gifts LIMIT 1"))
        row = result.first()
        if not row:
            print('Inserting dummy tx...')
            await conn.execute(text("""
            INSERT INTO global_gifts (
                tx_id, tx_ref, idempotency_key, sender_id, receiver_phone, receiver_name, 
                shop_id, product_id, quantity, unit_price, total_amount, amount_zmw, status, handshake_jwt
            ) VALUES (
                gen_random_uuid(), 'KLY-TEST-1234', 'test-idem-key', 'TestSender1', '+1234567890', 'Test Receiver',
                'test_shop_123', 'prod_123', 1, 50.00, 50.00, 1000.00, 'ESCROW_LOCKED'::escrowstatus, '9X4A-B72M'
            )
            """))
            print('FOUND: tx_ref=KLY-TEST-1234, status=ESCROW_LOCKED, handshake_jwt=9X4A-B72M')
        else:
            tx_ref = row[0]
            print(f'Updating found tx_ref={tx_ref} to ESCROW_LOCKED with token 9X4A-B72M...')
            await conn.execute(text(f"""
            UPDATE global_gifts SET status='ESCROW_LOCKED'::escrowstatus, handshake_jwt='9X4A-B72M'
            WHERE tx_ref='{tx_ref}'
            """))
            print(f'FOUND: tx_ref={tx_ref}, status=ESCROW_LOCKED, handshake_jwt=9X4A-B72M')

asyncio.run(setup_test_tx())
