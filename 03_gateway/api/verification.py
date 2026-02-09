"""
=============================================================================
KithLy Global Protocol - VERIFICATION API (Phase III-V)
verification.py - Collection Handshake & Token Verification
=============================================================================

Implements:
- QR code generation for collection tokens
- Token verification handshake (350: KEY_VERIFIED)
- ZRA fiscalization trigger
- Flutterwave disbursement trigger
"""

import os
import secrets
import string
import qrcode
import io
import base64
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/verification", tags=["Verification"])

# Configuration
ESCROW_TIMEOUT_HOURS = 48
QR_CODE_SIZE = 200


# =============================================================================
# MODELS
# =============================================================================

class TokenGenerationRequest(BaseModel):
    tx_id: str


class TokenGenerationResponse(BaseModel):
    tx_id: str
    collection_token: str
    qr_code_base64: str
    qr_code_url: Optional[str] = None
    expiry_timestamp: str
    share_message: str


class VerifyHandshakeRequest(BaseModel):
    tx_id: str
    collection_token: str
    shop_id: str
    verified_by: str = "shop_scan"  # shop_scan, manual_entry


class VerifyHandshakeResponse(BaseModel):
    success: bool
    tx_id: str
    new_status: int
    status_name: str
    zra_triggered: bool
    disbursement_triggered: bool
    message: str


# =============================================================================
# COLLECTION TOKEN GENERATION
# =============================================================================

def generate_collection_token() -> str:
    """Generate a 10-character collection token: KT-XXXX-XX"""
    chars = string.ascii_uppercase + string.digits
    # Remove ambiguous characters (0, O, I, 1, L)
    chars = chars.replace('O', '').replace('I', '').replace('L', '')
    
    part1 = ''.join(secrets.choice(chars) for _ in range(4))
    part2 = ''.join(secrets.choice(chars) for _ in range(2))
    
    return f"KT-{part1}-{part2}"


def create_qr_code(data: str, size: int = QR_CODE_SIZE) -> str:
    """
    Generate QR code and return as base64.
    Uses the same logic as sync_request.py for consistency.
    """
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Resize
    img = img.resize((size, size))
    
    # Convert to base64
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)
    
    return base64.b64encode(buffer.read()).decode('utf-8')


@router.post("/generate-token", response_model=TokenGenerationResponse)
async def generate_collection_token_endpoint(request: TokenGenerationRequest):
    """
    Generate collection token and QR code after payment confirmed.
    Called after status moves to 200 (FUNDS_LOCKED).
    """
    # Generate token
    token = generate_collection_token()
    
    # Calculate expiry (48 hours from now)
    expiry = datetime.utcnow() + timedelta(hours=ESCROW_TIMEOUT_HOURS)
    
    # Generate QR code with verification URL
    verification_url = f"https://kithly.com/collect/{request.tx_id}?token={token}"
    qr_base64 = create_qr_code(verification_url)
    
    # Create share message
    share_message = (
        f"🎁 Your KithLy Gift is Ready!\n\n"
        f"Collection Code: {token}\n"
        f"Valid until: {expiry.strftime('%d %b %Y, %H:%M')}\n\n"
        f"Show this to the shop or scan the QR code.\n"
        f"Powered by KithLy Global Protocol"
    )
    
    # TODO: Save token to database
    # UPDATE Global_Gifts 
    # SET collection_token = token, 
    #     expiry_timestamp = expiry,
    #     collection_qr_url = qr_url
    # WHERE tx_id = request.tx_id
    
    return TokenGenerationResponse(
        tx_id=request.tx_id,
        collection_token=token,
        qr_code_base64=qr_base64,
        expiry_timestamp=expiry.isoformat(),
        share_message=share_message,
    )


# =============================================================================
# VERIFICATION HANDSHAKE
# =============================================================================

@router.post("/verify-handshake", response_model=VerifyHandshakeResponse)
async def verify_handshake(request: VerifyHandshakeRequest):
    """
    Verify collection token when shop scans QR or enters code.
    
    Flow:
    1. Validate token matches tx_id
    2. Check token not expired
    3. Move status to 350 (KEY_VERIFIED)
    4. Trigger ZRA fiscalization (call_vsdc)
    5. Trigger Flutterwave disbursement
    """
    
    # TODO: Query database for actual token and expiry
    # For now, mock validation
    
    # Mock: Assume token is valid
    token_valid = True
    token_expired = False
    
    if not token_valid:
        return VerifyHandshakeResponse(
            success=False,
            tx_id=request.tx_id,
            new_status=0,
            status_name="INVALID_TOKEN",
            zra_triggered=False,
            disbursement_triggered=False,
            message="Invalid collection token",
        )
    
    if token_expired:
        return VerifyHandshakeResponse(
            success=False,
            tx_id=request.tx_id,
            new_status=900,
            status_name="EXPIRED",
            zra_triggered=False,
            disbursement_triggered=False,
            message="Collection token has expired. Refund initiated.",
        )
    
    # Status 350: KEY_VERIFIED
    new_status = 350
    
    # Trigger ZRA fiscalization
    zra_triggered = await _trigger_zra_fiscalization(request.tx_id, request.shop_id)
    
    # Trigger Flutterwave disbursement (only if ZRA succeeds)
    disbursement_triggered = False
    if zra_triggered:
        disbursement_triggered = await _trigger_flutterwave_disbursement(
            request.tx_id, 
            request.shop_id
        )
    
    # Update status to 400 if everything succeeded
    if zra_triggered and disbursement_triggered:
        new_status = 400
        status_name = "COMPLETED"
        message = "Gift collected! Shop paid, ZRA receipt issued."
    else:
        status_name = "KEY_VERIFIED"
        message = "Token verified. Awaiting settlement."
    
    return VerifyHandshakeResponse(
        success=True,
        tx_id=request.tx_id,
        new_status=new_status,
        status_name=status_name,
        zra_triggered=zra_triggered,
        disbursement_triggered=disbursement_triggered,
        message=message,
    )


async def _trigger_zra_fiscalization(tx_id: str, shop_id: str) -> bool:
    """Trigger ZRA VSDC fiscalization for the transaction."""
    try:
        # Import ZRA fiscalizer
        from services.zra_fiscalizer import call_vsdc
        
        # Call ZRA VSDC API
        # result = await call_vsdc(...)
        
        print(f"[ZRA] Fiscalization triggered for tx_id={tx_id}")
        return True
        
    except Exception as e:
        print(f"[ZRA ERROR] {e}")
        return False


async def _trigger_flutterwave_disbursement(tx_id: str, shop_id: str) -> bool:
    """Trigger Flutterwave Mobile Money disbursement to shop."""
    try:
        # Import payment service
        # from api.payments_ap2 import create_flutterwave_disbursement
        
        # Create disbursement
        # result = await create_flutterwave_disbursement(...)
        
        print(f"[FLUTTERWAVE] Disbursement triggered for tx_id={tx_id}")
        return True
        
    except Exception as e:
        print(f"[FLUTTERWAVE ERROR] {e}")
        return False


# =============================================================================
# ESCROW EXPIRY CHECK
# =============================================================================

@router.get("/check-expired")
async def check_expired_escrows():
    """
    Check for expired escrows and trigger refunds.
    Should be called by a scheduled worker.
    """
    # TODO: Query for expired transactions
    # SELECT tx_id, stripe_payment_ref 
    # FROM Global_Gifts 
    # WHERE status_code = 200 
    # AND expiry_timestamp < NOW()
    
    expired_count = 0
    refund_triggered = 0
    
    # Mock: No expired transactions
    
    return {
        "checked_at": datetime.utcnow().isoformat(),
        "expired_found": expired_count,
        "refunds_triggered": refund_triggered,
    }
