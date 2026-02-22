"""
=============================================================================
KithLy Global Protocol - WORKER NODE (Pipeline 1)
worker.py - Redis → PostgreSQL Drain Loop (The Safe Mutator)
=============================================================================

This standalone async script sits on the OTHER side of the Redis queue.
While the FastAPI gateway LPUSH-es payloads at sub-10ms, this worker does
the heavy lifting: BRPOP → idempotency check → INSERT → COMMIT.

Run it as a sidecar:
    python worker.py

Architecture:
    ┌──────────┐  LPUSH   ┌─────────┐  BRPOP   ┌──────────────┐
    │  FastAPI  │ ───────▶ │  Redis  │ ───────▶ │  worker.py   │
    │ (Bouncer) │          │  (RAM)  │          │ (this file)  │
    └──────────┘          └─────────┘          └──────┬───────┘
                                                      │ INSERT
                                                      ▼
                                               ┌──────────────┐
                                               │  PostgreSQL  │
                                               │ (global_gifts)│
                                               └──────────────┘

The worker is designed to be scaled horizontally: run 2, 5, or 10
instances and Redis will distribute jobs across them automatically
(BRPOP is consumer-group safe for a single-list queue).
=============================================================================
"""

import asyncio
import json
import uuid
from datetime import datetime

import redis.asyncio as aioredis
from sqlalchemy import select

# Re-use the SAME engine / session factory the gateway uses,
# so we read the same DATABASE_URL env var and model definitions.
from services.database import async_session, _get_redis_client
from services.models import Transaction


# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------

QUEUE_KEY = "kithly:ingestion:gifts"


# ---------------------------------------------------------------------------
# THE DRAIN LOOP
# ---------------------------------------------------------------------------

async def process_queue() -> None:
    """
    Infinite loop that blocks on Redis, pops one job at a time, and
    safely mutates PostgreSQL.

    Safety guarantees:
        • Idempotency — duplicate payloads are silently ignored.
        • Session safety — each job gets its own DB session via a
          context manager; if anything throws, the session rolls back.
        • Atomicity — db.commit() is called once per job.  If the
          INSERT succeeds, it is visible immediately to the gateway
          and webhook handlers.
    """
    print("=" * 65)
    print("  KithLy Worker Node — Pipeline 1 (Redis → PostgreSQL)")
    print("=" * 65)
    print(f"  Queue  : {QUEUE_KEY}")
    print(f"  Status : Listening...")
    print("=" * 65)

    while True:
        try:
            # ── 1. BLOCK until a job arrives ──────────────────────────
            # BRPOP pops from the RIGHT (oldest item — FIFO with LPUSH).
            # timeout=0 means "wait forever".  This call is non-blocking
            # to the event loop thanks to redis.asyncio.
            result = await _get_redis_client().brpop(QUEUE_KEY, timeout=0)

            if result is None:
                # Shouldn't happen with timeout=0, but guard anyway.
                continue

            # result is a tuple: (queue_name, payload_string)
            _, raw_payload = result

            print("\n📥 Job pulled from queue")

            # ── 2. Parse the JSON payload ─────────────────────────────
            payload = json.loads(raw_payload)
            idempotency_key = payload["idempotency_key"]
            tx_id = payload["tx_id"]

            print(f"   tx_id           : {tx_id}")
            print(f"   idempotency_key : {idempotency_key}")
            print(f"   sender          : {payload['sender_id']}")
            print(f"   receiver        : {payload['receiver_name']}")

            # ── 3. Open a DB session (context manager = auto-close) ───
            async with async_session() as db:

                # ── 4. IDEMPOTENCY CHECK ──────────────────────────────
                # If a previous worker instance (or a retry) already
                # committed this key, skip.  This prevents double-charges
                # even if the phone or gateway retransmits the payload.
                existing = await db.execute(
                    select(Transaction).where(
                        Transaction.idempotency_key == idempotency_key
                    )
                )
                if existing.scalar_one_or_none() is not None:
                    print("   ⚠️  Duplicate ignored. Prevented double-charge.")
                    continue

                # ── 5. MAP payload → ORM model ────────────────────────
                unit_price = float(payload.get("unit_price", 50.00))
                quantity = int(payload.get("quantity", 1))
                total = unit_price * quantity
                timestamp = (
                    datetime.fromisoformat(payload["timestamp"])
                    if "timestamp" in payload
                    else datetime.utcnow()
                )

                new_tx = Transaction(
                    tx_id=uuid.UUID(tx_id),
                    tx_ref=payload["tx_ref"],
                    idempotency_key=idempotency_key,
                    sender_id=payload["sender_id"],
                    receiver_phone=payload["receiver_phone"],
                    receiver_name=payload["receiver_name"],
                    shop_id=payload["shop_id"],
                    product_id=payload["product_id"],
                    quantity=quantity,
                    unit_price=unit_price,
                    total_amount=total,
                    amount_zmw=total,
                    message=payload.get("message"),
                    is_surprise=payload.get("is_surprise", False),
                    status=100,          # INITIATED
                    status_code=100,     # Legacy alias
                    created_at=timestamp,
                    updated_at=timestamp,
                )

                # ── 6. COMMIT ─────────────────────────────────────────
                db.add(new_tx)
                await db.commit()

                print(f"   ✅ Database committed → {payload['tx_ref']}")

        except json.JSONDecodeError as e:
            # Malformed payload — log and skip so the worker doesn't crash.
            print(f"   ❌ Bad JSON in queue: {e}")
            continue

        except KeyError as e:
            # Missing required field in the payload.
            print(f"   ❌ Missing field in payload: {e}")
            continue

        except Exception as e:
            # Catch-all — print and keep running.  The session context
            # manager rolls back automatically on exception.
            print(f"   ❌ Worker error: {type(e).__name__}: {e}")
            # Brief cooldown to avoid CPU spin on repeated failures.
            await asyncio.sleep(1)


# ---------------------------------------------------------------------------
# ENTRY POINT
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    asyncio.run(process_queue())
