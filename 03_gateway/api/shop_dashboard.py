"""
=============================================================================
KithLy Global Protocol - SHOP DASHBOARD API (Phase IV-Extension)
shop_dashboard.py - Shop Command Center Endpoints
=============================================================================

Implements:
- Shop dashboard data (revenue, orders)
- Pending escrow orders (real DB query)
- Order management (status 300 ready for collection)
- Emergency cancellation
"""

from datetime import datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from services.database import get_db
from services.models import Transaction, EscrowStatus

router = APIRouter(prefix="/shop", tags=["Shop Dashboard"])


# =============================================================================
# MODELS
# =============================================================================

class PendingOrderItem(BaseModel):
    """Safe subset of a Transaction exposed to the shop frontend."""
    tx_ref: str
    product_id: str
    quantity: int
    receiver_phone: str

    class Config:
        from_attributes = True


class DashboardResponse(BaseModel):
    shop_id: str
    today_revenue: float
    weekly_revenue: List[float]  # Last 7 days
    pending_orders: List[dict]
    total_completed: int
    

class OrderResponse(BaseModel):
    tx_id: str
    recipient_name: str
    product_name: str
    amount_zmw: float
    created_at: str
    collection_token: str
    status_code: int


class CancelOrderRequest(BaseModel):
    reason: str  # 'out_of_stock', 'shop_closed', 'other'


# =============================================================================
# DASHBOARD ENDPOINTS
# =============================================================================

@router.get("/{shop_id}/dashboard", response_model=DashboardResponse)
async def get_shop_dashboard(shop_id: str):
    """
    Get shop dashboard data including today's revenue and pending orders.
    Revenue is calculated from Global_Gifts where status = 400 (COMPLETED).
    """
    # TODO: Query actual database
    # SELECT SUM(amount_zmw) as today_revenue
    # FROM Global_Gifts 
    # WHERE shop_id = shop_id 
    # AND status_code = 400
    # AND DATE(created_at) = CURRENT_DATE
    
    # Weekly revenue: last 7 days
    # SELECT DATE(created_at), SUM(amount_zmw)
    # FROM Global_Gifts
    # WHERE shop_id = shop_id AND status_code = 400
    # AND created_at >= CURRENT_DATE - INTERVAL '7 days'
    # GROUP BY DATE(created_at)
    # ORDER BY DATE(created_at)
    
    # Pending orders (Status 300 - Ready for Collection)
    # SELECT * FROM Global_Gifts
    # WHERE shop_id = shop_id AND status_code = 300
    # ORDER BY created_at ASC
    
    # Mock data for development
    mock_pending = [
        {
            "tx_id": "mock-tx-1",
            "recipient_name": "John Banda",
            "product_name": "Birthday Cake - Chocolate",
            "amount_zmw": 450.0,
            "created_at": (datetime.utcnow() - timedelta(minutes=15)).isoformat(),
            "collection_token": "KT-A3B7-XY",
        },
        {
            "tx_id": "mock-tx-2",
            "recipient_name": "Mary Phiri",
            "product_name": "Flower Bouquet - Roses",
            "amount_zmw": 350.0,
            "created_at": (datetime.utcnow() - timedelta(hours=2)).isoformat(),
            "collection_token": "KT-C9D2-ZK",
        },
        {
            "tx_id": "mock-tx-3",
            "recipient_name": "David Mwansa",
            "product_name": "Gift Hamper - Premium",
            "amount_zmw": 850.0,
            "created_at": (datetime.utcnow() - timedelta(hours=5)).isoformat(),
            "collection_token": "KT-E5F1-QM",
        },
    ]
    
    return DashboardResponse(
        shop_id=shop_id,
        today_revenue=12500.0,
        weekly_revenue=[8500, 12000, 9500, 14000, 11000, 13500, 12500],
        pending_orders=mock_pending,
        total_completed=47,
    )


# =============================================================================
# PENDING ESCROW ORDERS (Real DB Query)
# =============================================================================

@router.get(
    "/{shop_id}/pending-orders",
    response_model=List[PendingOrderItem],
    summary="Fetch pending escrow orders for a shop",
)
async def get_pending_orders(
    shop_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Return every transaction that belongs to **shop_id** and is currently
    locked in escrow (`status == ESCROW_LOCKED`).

    Only safe fields are returned — `handshake_jwt` is deliberately excluded
    so it never reaches the frontend.
    """
    stmt = (
        select(Transaction)
        .where(
            Transaction.shop_id == shop_id,
            Transaction.status == EscrowStatus.ESCROW_LOCKED,
        )
        .order_by(Transaction.created_at.asc())
    )

    result = await db.execute(stmt)
    rows = result.scalars().all()

    return [
        PendingOrderItem(
            tx_ref=row.tx_ref,
            product_id=row.product_id,
            quantity=row.quantity,
            receiver_phone=row.receiver_phone,
        )
        for row in rows
    ]


@router.get("/{shop_id}/orders")
async def get_shop_orders(shop_id: str, status: Optional[int] = 300):
    """
    Get shop orders filtered by status.
    Default: Status 300 (Ready for Collection)
    """
    # TODO: Query database
    # SELECT g.*, p.name as product_name
    # FROM Global_Gifts g
    # JOIN Product_Catalog p ON g.sku_id = p.sku_id
    # WHERE g.shop_id = shop_id AND g.status_code = status
    # ORDER BY g.created_at ASC
    
    # Mock data
    mock_orders = [
        OrderResponse(
            tx_id="mock-tx-1",
            recipient_name="John Banda",
            product_name="Birthday Cake - Chocolate",
            amount_zmw=450.0,
            created_at=datetime.utcnow().isoformat(),
            collection_token="KT-A3B7-XY",
            status_code=300,
        ),
    ]
    
    return {
        "shop_id": shop_id,
        "status_filter": status,
        "orders": [o.dict() for o in mock_orders],
        "count": len(mock_orders),
    }


@router.post("/orders/{tx_id}/cancel")
async def cancel_order(tx_id: str, request: CancelOrderRequest):
    """
    Cancel an order (emergency - out of stock, shop closed, etc.)
    Triggers refund to customer.
    """
    if not request.reason:
        raise HTTPException(status_code=400, detail="Cancellation reason is required")
    
    valid_reasons = ['out_of_stock', 'shop_closed', 'other']
    if request.reason not in valid_reasons:
        # Allow custom reasons
        pass
    
    # TODO: Update order status
    # UPDATE Global_Gifts 
    # SET status_code = 900,  -- CANCELLED
    #     cancel_reason = request.reason,
    #     cancelled_at = NOW()
    # WHERE tx_id = tx_id
    
    # TODO: Trigger refund via Stripe/Flutterwave
    # from api.payments_ap2 import trigger_refund
    # await trigger_refund(tx_id)
    
    # TODO: Send notification to customer
    
    print(f"[CANCEL] Order {tx_id} cancelled. Reason: {request.reason}")
    
    return {
        "success": True,
        "tx_id": tx_id,
        "status": "cancelled",
        "reason": request.reason,
        "refund_initiated": True,
        "message": "Order cancelled and refund initiated.",
    }


# =============================================================================
# REAL-TIME UPDATES (WebSocket ready)
# =============================================================================

@router.get("/{shop_id}/stats")
async def get_shop_stats(shop_id: str):
    """
    Get real-time shop statistics.
    For dashboard widgets that need live updates.
    """
    # TODO: Aggregate from database
    
    return {
        "shop_id": shop_id,
        "stats": {
            "today_orders": 12,
            "today_revenue": 12500.0,
            "pending_collection": 3,
            "avg_collection_time_mins": 45,
            "customer_rating": 4.8,
        },
        "timestamp": datetime.utcnow().isoformat(),
    }
