"""
=============================================================================
KithLy Global Protocol - ORM MODELS (Phase V)
models.py - SQLAlchemy Models mapped to 01_bedrock schema
=============================================================================

Maps to tables defined in:
  01_bedrock/schema/001_initial_ledger.sql   → Transaction (Global_Gifts)
"""

from datetime import datetime
from sqlalchemy import Column, String, Integer, Numeric, Boolean, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID as PG_UUID

from .database import Base


class Transaction(Base):
    """
    ORM mapping for the `Global_Gifts` table.

    Status codes (The Protocol):
        100 - INITIATED / Pending
        200 - CONFIRMED / Payment Locked
        250 - SETTLED   / Shop disbursement verified
        300 - FULFILLING
        400 - DELIVERED
        ...
    """

    __tablename__ = "global_gifts"

    # Primary key
    tx_id = Column(PG_UUID(as_uuid=True), primary_key=True)

    # Idempotency
    idempotency_key = Column(Text, unique=True, nullable=False)

    # Product & amount
    sku_id = Column(String(100), nullable=False)
    amount_zmw = Column(Numeric(12, 2), nullable=False)

    # Status
    status_code = Column(Integer, nullable=False, default=100)

    # Currency Oracle (Phase V)
    final_collected_gbp = Column(Numeric(12, 2), nullable=True)
    final_collected_usd = Column(Numeric(12, 2), nullable=True)
    fx_rate_applied = Column(Numeric(12, 6), nullable=True)
    volatility_buffer = Column(Boolean, default=True)
    stripe_payment_ref = Column(String(100), nullable=True)

    # Proof-of-Collection (Phase III-V)
    collection_token = Column(String(12), nullable=True)
    collection_qr_url = Column(Text, nullable=True)
    expiry_timestamp = Column(DateTime(timezone=True), nullable=True)
    is_settled = Column(Boolean, default=False)
    flutterwave_ref = Column(String(100), nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self) -> str:
        return f"<Transaction tx_id={self.tx_id} status={self.status_code}>"
