"""
=============================================================================
KithLy Global Protocol - GATEWAY APPLICATION (Phase VI)
app.py - FastAPI Application Entry Point
=============================================================================

Mounts all API routers under the /api prefix.
Used by both uvicorn (production) and TestClient (testing).

Includes a lifespan-managed background listener that consumes
escrow-locked events from Redis and dispatches SMS notifications.
"""

import asyncio
import json
import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI

from api.admin import router as admin_router
from api.gifts import router as gifts_router
from api.auth import router as auth_router

from services.database import get_redis
from services.notifications.interface import (
    NotificationPayload,
    NotificationType,
)
from services.notifications.console_mock import ConsoleMockProvider

logger = logging.getLogger("kithly.events")

# ---------------------------------------------------------------------------
# NOTIFICATION PROVIDER (swap for TwilioSMS / FirebasePush in production)
# ---------------------------------------------------------------------------
_notifier = ConsoleMockProvider()

ESCROW_EVENT_QUEUE = "kithly:events:escrow_locked"


# ---------------------------------------------------------------------------
# REDIS EVENT LISTENER
# ---------------------------------------------------------------------------

async def listen_for_escrow_events(redis_pool) -> None:
    """
    Infinite loop that blocks on the ``kithly:events:escrow_locked`` Redis
    list.  When the C++ orchestrator pushes an event after locking escrow,
    this function pops the event, parses the JSON, and sends an SMS
    notification to the receiver.

    Designed to run as an ``asyncio.Task`` during the FastAPI lifespan.
    """
    logger.info("📡 Escrow event listener started on queue: %s", ESCROW_EVENT_QUEUE)

    while True:
        try:
            # BRPOP blocks until an event arrives (FIFO with C++ LPUSH)
            result = await redis_pool.brpop(ESCROW_EVENT_QUEUE, timeout=0)

            if result is None:
                continue

            _, raw_payload = result
            event = json.loads(raw_payload)

            tx_ref = event.get("tx_ref", "UNKNOWN")
            receiver_phone = event.get("receiver_phone", "")
            handshake_code = event.get("handshake_code", "")

            logger.info(
                "🔔 Escrow event received — tx_ref=%s receiver=%s",
                tx_ref,
                receiver_phone,
            )

            # Format the SMS body exactly as specified
            sms_body = (
                f"KithLy: A gift has been locked in Escrow for you! "
                f"Give the driver this code to claim it: {handshake_code}"
            )

            # Dispatch via the notification interface (ConsoleMock for now)
            await _notifier.send(
                NotificationPayload(
                    recipient_id=receiver_phone,
                    recipient_contact=receiver_phone,
                    notification_type=NotificationType.GIFT_RECEIVED,
                    title="KithLy Escrow Locked",
                    body=sms_body,
                    tx_id=tx_ref,
                )
            )

        except json.JSONDecodeError as e:
            logger.error("❌ Bad JSON from escrow event queue: %s", e)
            continue

        except asyncio.CancelledError:
            logger.info("🛑 Escrow event listener shutting down.")
            break

        except Exception as e:
            logger.error("❌ Escrow listener error: %s", e)
            await asyncio.sleep(1)


# ---------------------------------------------------------------------------
# FASTAPI LIFESPAN
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.

    On startup  → spawns the Redis escrow-event listener as a background task.
    On shutdown → cancels the listener gracefully.
    """
    if os.environ.get("TESTING") != "True":
        redis_pool = await get_redis()
        task = asyncio.create_task(listen_for_escrow_events(redis_pool))
        logger.info("✅ Background escrow listener task created.")

        yield  # ← application is running

        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass
        logger.info("🛑 Background escrow listener task cancelled.")
    else:
        yield  # ← application is running in test mode


# ---------------------------------------------------------------------------
# APPLICATION
# ---------------------------------------------------------------------------

app = FastAPI(
    title="KithLy Global Protocol - Gateway",
    description="Gift delivery orchestration API",
    version="0.6.0",
    lifespan=lifespan,
)

# Mount routers
app.include_router(admin_router, prefix="/api")
app.include_router(gifts_router, prefix="/api")
app.include_router(auth_router, prefix="/api")
