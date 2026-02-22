"""
=============================================================================
KithLy Global Protocol - DATABASE MODULE (Phase V)
database.py - Async SQLAlchemy Engine & Session Factory
=============================================================================

Provides `get_db()` for FastAPI dependency injection.
Uses asyncpg as the async PostgreSQL driver.
"""

import os
from dotenv import load_dotenv
load_dotenv()

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

# ---------------------------------------------------------------------------
# DATABASE URL
# ---------------------------------------------------------------------------
# Reads from env; falls back to local dev PostgreSQL.
# Format: postgresql+asyncpg://user:password@host:port/dbname
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@localhost:5432/kithly"
)

# ---------------------------------------------------------------------------
# ENGINE & SESSION
# ---------------------------------------------------------------------------

engine = create_async_engine(DATABASE_URL, echo=False, future=True)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# ---------------------------------------------------------------------------
# DECLARATIVE BASE
# ---------------------------------------------------------------------------

class Base(DeclarativeBase):
    """Shared declarative base for all ORM models."""
    pass


# ---------------------------------------------------------------------------
# FASTAPI DEPENDENCY
# ---------------------------------------------------------------------------

async def get_db() -> AsyncSession:  # type: ignore[misc]
    """
    Yield an async database session for FastAPI `Depends()`.

    Usage:
        @router.post("/example")
        async def example(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


# ---------------------------------------------------------------------------
# REDIS (Ingestion Queue / Shock Absorber)
# ---------------------------------------------------------------------------
# Used by the Ingestion Pipeline — endpoints push payloads into a Redis list
# and return 202 Accepted instantly.  C++ worker nodes BRPOP from the other side.

import redis.asyncio as aioredis

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Lazy singleton — created on first use so it binds to the current event loop.
_redis_client: aioredis.Redis | None = None


def _get_redis_client() -> aioredis.Redis:
    """Return (or create) the shared async Redis client."""
    global _redis_client
    if _redis_client is None:
        _redis_client = aioredis.from_url(REDIS_URL, decode_responses=True)
    return _redis_client


# Kept for backward-compat with worker.py (imports redis_pool directly)
redis_pool = None  # type: ignore[assignment]


async def get_redis() -> aioredis.Redis:  # type: ignore[misc]
    """
    Return the shared async Redis client for FastAPI ``Depends()``.

    Usage::

        @router.post("/example")
        async def example(r: aioredis.Redis = Depends(get_redis)):
            await r.lpush("queue:name", payload)
    """
    return _get_redis_client()


