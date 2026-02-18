"""
=============================================================================
KithLy Global Protocol - LAYER 3: THE TRANSLATOR (Python/FastAPI)
gifts.py - Gift Transaction Endpoints with AI Auditor Integration
=============================================================================
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import IntEnum
import uuid
import hashlib

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from services.database import get_db
from services.models import Transaction

from .auth import get_current_user, require_role, TokenData
from services.gemini_vision import get_vision_service, AuditResult

router = APIRouter(prefix="/gifts", tags=["Gifts"])

# ---------------------------------------------------------------------------
# IDEMPOTENCY: Now backed by the Transaction table in PostgreSQL.
# No more in-memory dict — orders survive server restarts.
# ---------------------------------------------------------------------------


# === Status Codes (The Protocol) ===

class GiftStatus(IntEnum):
    INITIATED = 100
    PAID = 200
    ASSIGNED = 310
    PICKUP_EN_ROUTE = 320
    PICKED_UP = 330
    DELIVERY_EN_ROUTE = 340
    DELIVERED = 400
    CONFIRMED = 500
    GRATITUDE_SENT = 600
    COMPLETED = 700
    HELD_FOR_REVIEW = 800  # AI confidence < 0.85
    RESOLVED = 900


STATUS_NAMES = {
    100: "Gift Created",
    200: "Payment Confirmed",
    310: "Rider Assigned",
    320: "Rider En Route to Shop",
    330: "Gift Picked Up",
    340: "Rider En Route to Receiver",
    400: "Gift Delivered",
    500: "Receipt Confirmed",
    600: "Gratitude Sent",
    700: "Completed",
    800: "Held for Review",
    900: "Resolved"
}

# AI confidence threshold
CONFIDENCE_THRESHOLD = 0.85


# === Pydantic Models ===

class GiftCreate(BaseModel):
    receiver_phone: str
    receiver_name: str
    shop_id: str
    product_id: str
    quantity: int = Field(default=1, ge=1)
    message: Optional[str] = None
    is_surprise: bool = False
    idempotency_key: str = Field(default_factory=lambda: str(uuid.uuid4()))


class GiftResponse(BaseModel):
    tx_id: str
    tx_ref: str
    status: int
    status_name: str
    
    sender_id: str
    receiver_phone: str
    receiver_name: str
    shop_id: str
    product_id: str
    quantity: int
    
    unit_price: float
    total_amount: float
    currency: str = "ZMW"
    
    message: Optional[str]
    is_surprise: bool
    
    rider_id: Optional[str]
    rider_name: Optional[str]
    
    created_at: datetime
    updated_at: datetime
    estimated_delivery: Optional[datetime]


class ProofUploadResponse(BaseModel):
    tx_id: str
    proof_accepted: bool
    ai_confidence: float
    match: bool
    zra_ref: Optional[str]
    new_status: int
    new_status_name: str
    message: str


class StatusUpdate(BaseModel):
    status: int
    notes: Optional[str] = None


class StatusHistoryEntry(BaseModel):
    from_status: int
    to_status: int
    at: datetime
    by: Optional[str]


# === Endpoints ===

@router.post("/", response_model=GiftResponse)
async def create_gift(
    gift: GiftCreate,
    current_user: TokenData = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),  # Inject Database Session
):
    """
    Create a new gift transaction (idempotent & persistent).

    If a transaction with the same idempotency_key already exists,
    the original response is returned (200 OK) instead of creating
    a duplicate. Otherwise a new gift is created (201 CREATED).
    """
    # ── 1. The "Iron" Idempotency Check (Check DB, not RAM) ──────────
    result = await db.execute(
        select(Transaction).where(
            Transaction.idempotency_key == gift.idempotency_key
        )
    )
    existing_tx = result.scalar_one_or_none()

    if existing_tx:
        # Return the existing data instantly — no duplicate charge.
        return GiftResponse(
            tx_id=str(existing_tx.tx_id),
            tx_ref=existing_tx.tx_ref,
            status=existing_tx.status,
            status_name=STATUS_NAMES.get(existing_tx.status, "Unknown"),
            sender_id=existing_tx.sender_id,
            receiver_phone=existing_tx.receiver_phone,
            receiver_name=existing_tx.receiver_name,
            shop_id=existing_tx.shop_id,
            product_id=existing_tx.product_id,
            quantity=existing_tx.quantity,
            unit_price=float(existing_tx.unit_price),
            total_amount=float(existing_tx.total_amount),
            message=existing_tx.message,
            is_surprise=existing_tx.is_surprise,
            rider_id=existing_tx.rider_id,
            rider_name=None,
            created_at=existing_tx.created_at,
            updated_at=existing_tx.updated_at,
            estimated_delivery=existing_tx.estimated_delivery,
        )

    # ── 2. Create New Transaction (The Write-Ahead Log) ──────────────
    tx_id = str(uuid.uuid4())
    tx_ref = f"KLY-2026-{tx_id[:8].upper()}"
    unit_price = 50.00  # TODO: Lookup real price from Product table

    new_tx = Transaction(
        tx_id=tx_id,
        tx_ref=tx_ref,
        idempotency_key=gift.idempotency_key,
        sender_id=current_user.user_id,
        receiver_phone=gift.receiver_phone,
        receiver_name=gift.receiver_name,
        shop_id=gift.shop_id,
        product_id=gift.product_id,
        quantity=gift.quantity,
        unit_price=unit_price,
        total_amount=unit_price * gift.quantity,
        amount_zmw=unit_price * gift.quantity,
        message=gift.message,
        is_surprise=gift.is_surprise,
        status=GiftStatus.INITIATED,
        status_code=GiftStatus.INITIATED,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(new_tx)
    await db.commit()
    await db.refresh(new_tx)

    return GiftResponse(
        tx_id=str(new_tx.tx_id),
        tx_ref=new_tx.tx_ref,
        status=new_tx.status,
        status_name=STATUS_NAMES[GiftStatus.INITIATED],
        sender_id=new_tx.sender_id,
        receiver_phone=new_tx.receiver_phone,
        receiver_name=new_tx.receiver_name,
        shop_id=new_tx.shop_id,
        product_id=new_tx.product_id,
        quantity=new_tx.quantity,
        unit_price=float(new_tx.unit_price),
        total_amount=float(new_tx.total_amount),
        message=new_tx.message,
        is_surprise=new_tx.is_surprise,
        rider_id=None,
        rider_name=None,
        created_at=new_tx.created_at,
        updated_at=new_tx.updated_at,
        estimated_delivery=None,
    )


@router.post("/{tx_id}/upload-proof", response_model=ProofUploadResponse)
async def upload_delivery_proof(
    tx_id: str,
    expected_sku: str,
    photo: UploadFile = File(...),
    current_user: TokenData = Depends(require_role("rider", "admin"))
):
    """
    Upload delivery proof photo. AI Auditor verifies the image.
    
    Safety Interlock:
    - If confidence >= 0.85 → Status 400 (DELIVERED)
    - If confidence < 0.85 → Status 800 (HELD_FOR_REVIEW)
    """
    # Read image bytes
    image_bytes = await photo.read()
    
    # Generate SHA-256 hash for evidence vault
    receipt_hash = hashlib.sha256(image_bytes).hexdigest()
    
    # Call AI Auditor (Gemini Vision)
    vision_service = get_vision_service()
    audit_result: AuditResult = await vision_service.analyze_delivery_proof(
        image_bytes=image_bytes,
        expected_sku=expected_sku
    )
    
    # Determine status based on AI confidence
    if audit_result.confidence >= CONFIDENCE_THRESHOLD:
        new_status = GiftStatus.DELIVERED
        proof_accepted = True
        message = f"Delivery verified by AI (confidence: {audit_result.confidence:.2f})"
    else:
        new_status = GiftStatus.HELD_FOR_REVIEW
        proof_accepted = False
        message = f"Held for manual review (AI confidence: {audit_result.confidence:.2f} < {CONFIDENCE_THRESHOLD})"
    
    # TODO: Update status in C++ Core via internal API
    # TODO: Store evidence in Delivery_Proofs table with receipt_hash
    
    return ProofUploadResponse(
        tx_id=tx_id,
        proof_accepted=proof_accepted,
        ai_confidence=audit_result.confidence,
        match=audit_result.match,
        zra_ref=audit_result.zra_ref,
        new_status=new_status,
        new_status_name=STATUS_NAMES[new_status],
        message=message
    )


@router.get("/{tx_id}", response_model=GiftResponse)
async def get_gift(
    tx_id: str,
    current_user: TokenData = Depends(get_current_user)
):
    """Get gift transaction by ID."""
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Gift {tx_id} not found"
    )


@router.get("/", response_model=List[GiftResponse])
async def list_gifts(
    role: str = Query("sender", regex="^(sender|receiver)$"),
    status: Optional[int] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: TokenData = Depends(get_current_user)
):
    """List user's gifts as sender or receiver."""
    return []


@router.get("/by-ref/{tx_ref}", response_model=GiftResponse)
async def get_gift_by_ref(
    tx_ref: str,
    current_user: TokenData = Depends(get_current_user)
):
    """Get gift transaction by reference (KLY-XXXX-XXXX)."""
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Gift {tx_ref} not found"
    )


@router.post("/{tx_id}/pay", response_model=GiftResponse)
async def mark_paid(
    tx_id: str,
    payment_ref: str,
    current_user: TokenData = Depends(get_current_user)
):
    """Mark gift as paid. Status: 100 -> 200"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.post("/{tx_id}/assign", response_model=GiftResponse)
async def assign_rider(
    tx_id: str,
    rider_id: str,
    current_user: TokenData = Depends(require_role("admin", "shop_admin"))
):
    """Assign a rider. Status: 200 -> 310"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.post("/{tx_id}/status", response_model=GiftResponse)
async def update_status(
    tx_id: str,
    update: StatusUpdate,
    current_user: TokenData = Depends(get_current_user)
):
    """Update gift status (for riders and receivers)."""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.get("/{tx_id}/history", response_model=List[StatusHistoryEntry])
async def get_status_history(
    tx_id: str,
    current_user: TokenData = Depends(get_current_user)
):
    """Get full status history for a gift."""
    return []


@router.post("/{tx_id}/confirm", response_model=GiftResponse)
async def confirm_receipt(
    tx_id: str,
    current_user: TokenData = Depends(get_current_user)
):
    """Receiver confirms receipt. Status: 400 -> 500"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)


@router.post("/{tx_id}/dispute")
async def raise_dispute(
    tx_id: str,
    reason: str,
    current_user: TokenData = Depends(get_current_user)
):
    """Raise a dispute. Status: * -> 800"""
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED)
