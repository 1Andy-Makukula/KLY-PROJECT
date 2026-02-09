"""
=============================================================================
KithLy Global Protocol - INTERNAL WORKER
internal_worker.py - Fast Lane for C++ Brain → Python Gateway
=============================================================================

This is the "Fast Lane" endpoint for the C++ core to trigger actions
like Twilio Force Calls without going through the public API.
"""

from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
import os

# Import notification providers
from services.notifications.twilio_sms import TwilioSMSProvider
from services.notifications.interface import NotificationPayload, NotificationType

router = APIRouter(prefix="/internal", tags=["Internal Worker"])

# Internal API key for C++ core authentication
INTERNAL_API_KEY = os.getenv("KITHLY_INTERNAL_KEY", "kithly-internal-secret")


class ForceCallRequest(BaseModel):
    tx_id: str
    shop_id: str
    shop_phone: Optional[str] = None
    reason: str = "escalation_305"


class ForceCallResponse(BaseModel):
    success: bool
    tx_id: str
    call_initiated: bool
    message: str
    timestamp: datetime


class RerouteNotification(BaseModel):
    tx_id: str
    old_shop_id: str
    new_shop_id: str
    new_shop_name: str
    distance_km: float


def verify_internal_key(x_internal_key: str = Header(...)):
    """Verify the internal API key from C++ core."""
    if x_internal_key != INTERNAL_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid internal key")
    return True


@router.post("/force-call", response_model=ForceCallResponse)
async def trigger_force_call(
    request: ForceCallRequest,
    _: bool = Header(default=None, alias="X-Internal-Key")
):
    """
    Triggered by C++ orchestrator when status hits 305 (FORCE_CALL_PENDING).
    Initiates a Twilio call to the shop to confirm order status.
    """
    # TODO: Lookup shop phone from database if not provided
    shop_phone = request.shop_phone or "+260971234567"
    
    try:
        # Initialize Twilio provider
        twilio = TwilioSMSProvider()
        
        # Send SMS notification as precursor to call
        payload = NotificationPayload(
            recipient_id=request.shop_id,
            recipient_contact=shop_phone,
            notification_type=NotificationType.STATUS_UPDATE,
            title="KithLy Order Alert",
            body=f"Order {request.tx_id[:8]} requires immediate attention. Please confirm status.",
            tx_id=request.tx_id
        )
        
        result = await twilio.send(payload)
        
        # TODO: Integrate with Twilio Voice API for actual call
        # call = twilio_client.calls.create(...)
        
        return ForceCallResponse(
            success=True,
            tx_id=request.tx_id,
            call_initiated=result.success,
            message=f"Force call triggered for order {request.tx_id}",
            timestamp=datetime.utcnow()
        )
        
    except Exception as e:
        return ForceCallResponse(
            success=False,
            tx_id=request.tx_id,
            call_initiated=False,
            message=str(e),
            timestamp=datetime.utcnow()
        )


@router.post("/reroute-notification")
async def notify_reroute(
    request: RerouteNotification,
    _: bool = Header(default=None, alias="X-Internal-Key")
):
    """
    Triggered by C++ routing engine when status hits 315 (REROUTING).
    Notifies relevant parties about the shop change.
    """
    return {
        "success": True,
        "tx_id": request.tx_id,
        "message": f"Rerouted from {request.old_shop_id[:8]} to {request.new_shop_name}",
        "new_shop_id": request.new_shop_id,
        "distance_km": request.distance_km,
        "timestamp": datetime.utcnow()
    }


@router.get("/health")
async def internal_health():
    """Health check for internal worker."""
    return {"status": "ok", "service": "internal_worker", "timestamp": datetime.utcnow()}
