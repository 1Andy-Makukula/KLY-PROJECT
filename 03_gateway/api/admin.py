"""
=============================================================================
KithLy Global Protocol - ADMIN API (Phase IV-Extension)
admin.py - God Mode Admin Endpoints
=============================================================================

Implements:
- Shop approval workflow
- Active rider tracking
- Admin dashboard data
"""

from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/admin", tags=["Admin"])


# =============================================================================
# MODELS
# =============================================================================

class ShopApprovalAction(BaseModel):
    notes: Optional[str] = None


class ShopRejectionAction(BaseModel):
    reason: str


class PendingShopResponse(BaseModel):
    shop_id: str
    name: str
    owner_name: str
    address: str
    city: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    nrc_id_url: Optional[str] = None
    shopfront_photo_url: Optional[str] = None
    tpin: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    created_at: str


class ActiveRiderResponse(BaseModel):
    rider_id: str
    name: str
    latitude: float
    longitude: float
    current_order_id: str
    status: str  # 'delivering', 'picking_up', 'idle'
    last_update: str


# =============================================================================
# SHOP APPROVAL ENDPOINTS
# =============================================================================

@router.get("/shops/pending", response_model=List[PendingShopResponse])
async def get_pending_shops():
    """
    Get all shops with admin_approval_status = 'pending'.
    Returns shop details including NRC photo and location.
    """
    # TODO: Query database
    # SELECT * FROM Shops 
    # WHERE admin_approval_status = 'pending'
    # ORDER BY created_at ASC
    
    # Mock data for development
    return [
        PendingShopResponse(
            shop_id="mock-shop-1",
            name="Manda Hill Flowers",
            owner_name="Grace Mwanza",
            address="Manda Hill Mall, Shop 42",
            city="Lusaka",
            latitude=-15.3892,
            longitude=28.3228,
            tpin="1234567890",
            email="grace@mandaflowers.com",
            phone_number="+260977123456",
            created_at=datetime.utcnow().isoformat(),
        ),
        PendingShopResponse(
            shop_id="mock-shop-2",
            name="Cairo Road Gifts",
            owner_name="John Banda",
            address="123 Cairo Road",
            city="Lusaka",
            latitude=-15.4167,
            longitude=28.2833,
            tpin="0987654321",
            email="john@cairogifts.com",
            phone_number="+260955987654",
            created_at=datetime.utcnow().isoformat(),
        ),
    ]


@router.post("/shops/{shop_id}/approve")
async def approve_shop(shop_id: str, action: ShopApprovalAction):
    """
    Approve a pending shop application.
    Updates admin_approval_status to 'approved' and is_verified to true.
    """
    # TODO: Update database
    # UPDATE Shops 
    # SET admin_approval_status = 'approved',
    #     is_verified = true,
    #     verified_at = NOW(),
    #     admin_notes = action.notes
    # WHERE shop_id = shop_id
    
    # TODO: Send approval email to shop owner
    # TODO: Send push notification
    
    print(f"[ADMIN] Shop {shop_id} approved. Notes: {action.notes}")
    
    return {
        "success": True,
        "shop_id": shop_id,
        "status": "approved",
        "message": "Shop has been approved and activated.",
    }


@router.post("/shops/{shop_id}/reject")
async def reject_shop(shop_id: str, action: ShopRejectionAction):
    """
    Reject a pending shop application.
    Updates admin_approval_status to 'rejected' and sends notification.
    """
    if not action.reason:
        raise HTTPException(status_code=400, detail="Rejection reason is required")
    
    # TODO: Update database
    # UPDATE Shops 
    # SET admin_approval_status = 'rejected',
    #     admin_notes = action.reason
    # WHERE shop_id = shop_id
    
    # TODO: Send rejection email with reason
    
    print(f"[ADMIN] Shop {shop_id} rejected. Reason: {action.reason}")
    
    return {
        "success": True,
        "shop_id": shop_id,
        "status": "rejected",
        "reason": action.reason,
        "message": "Shop application has been rejected. Email sent to owner.",
    }


# =============================================================================
# RIDER TRACKING ENDPOINTS
# =============================================================================

@router.get("/riders/active", response_model=List[ActiveRiderResponse])
async def get_active_riders():
    """
    Get all active riders with their current locations.
    For Flight Map visualization.
    """
    # TODO: Query database with real-time location data
    # SELECT r.*, l.latitude, l.longitude, l.updated_at
    # FROM Riders r
    # JOIN Rider_Locations l ON r.rider_id = l.rider_id
    # WHERE r.status IN ('delivering', 'picking_up')
    
    # Mock data for development
    return [
        ActiveRiderResponse(
            rider_id="rider-1",
            name="Emmanuel Phiri",
            latitude=-15.3920,
            longitude=28.3180,
            current_order_id="order-abc-123",
            status="delivering",
            last_update=datetime.utcnow().isoformat(),
        ),
        ActiveRiderResponse(
            rider_id="rider-2",
            name="Joseph Banda",
            latitude=-15.4010,
            longitude=28.2890,
            current_order_id="order-def-456",
            status="delivering",
            last_update=datetime.utcnow().isoformat(),
        ),
        ActiveRiderResponse(
            rider_id="rider-3",
            name="Moses Tembo",
            latitude=-15.3780,
            longitude=28.3450,
            current_order_id="order-ghi-789",
            status="picking_up",
            last_update=datetime.utcnow().isoformat(),
        ),
    ]


@router.post("/riders/{rider_id}/location")
async def update_rider_location(
    rider_id: str, 
    latitude: float, 
    longitude: float
):
    """
    Update rider's current location (called by rider app).
    """
    # TODO: Update database
    # INSERT INTO Rider_Locations (rider_id, latitude, longitude, updated_at)
    # VALUES (rider_id, latitude, longitude, NOW())
    # ON CONFLICT (rider_id) DO UPDATE
    # SET latitude = latitude, longitude = longitude, updated_at = NOW()
    
    print(f"[RIDER] Location update: {rider_id} -> ({latitude}, {longitude})")
    
    return {
        "success": True,
        "rider_id": rider_id,
        "updated_at": datetime.utcnow().isoformat(),
    }
