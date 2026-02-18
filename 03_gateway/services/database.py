"""
=============================================================================
KithLy Global Protocol - DATABASE MODULE (Phase V)
database.py - Async SQLAlchemy Engine & Session Factory
=============================================================================

Provides `get_db()` for FastAPI dependency injection.
Uses asyncpg as the async PostgreSQL driver.
"""

import os
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
