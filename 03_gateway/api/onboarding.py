"""
=============================================================================
KithLy Global Protocol - SHOP ONBOARDING API (Phase V)
onboarding.py - Step-by-Step Registration Endpoints
=============================================================================

Steps:
1. Identity (Name, Phone, Email)
2. Legal (Entity Type, PACRA, TPIN, NRC)
3. Location (Address, Coordinates, Shopfront Photo)
4. Financial (Settlement Type, Account Details)
5. Review (Submit for Admin Approval)
"""

import os
import re
from typing import Optional
from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel, validator
from datetime import datetime

router = APIRouter(prefix="/shop/register", tags=["Shop Onboarding"])


# =============================================================================
# REQUEST MODELS
# =============================================================================

class Step1IdentityRequest(BaseModel):
    shop_name: str
    owner_name: str
    phone_number: str
    email: str
    
    @validator('phone_number')
    def validate_phone(cls, v):
        # Zambian phone: 10 digits, starts with 09x
        pattern = r'^09[5-7]\d{7}$'
        if not re.match(pattern, v):
            raise ValueError('Invalid Zambian phone number (must be 10 digits, start with 095/096/097)')
        return v
    
    @validator('email')
    def validate_email(cls, v):
        pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
        if not re.match(pattern, v.lower()):
            raise ValueError('Invalid email address')
        return v.lower()


class Step2LegalRequest(BaseModel):
    shop_id: str
    legal_type: str  # sole_prop, ltd, partnership
    tpin: str
    pacra_number: Optional[str] = None
    nrc_id_url: Optional[str] = None
    
    @validator('legal_type')
    def validate_legal_type(cls, v):
        valid_types = ['sole_prop', 'ltd', 'partnership']
        if v not in valid_types:
            raise ValueError(f'legal_type must be one of: {valid_types}')
        return v
    
    @validator('tpin')
    def validate_tpin(cls, v):
        # ZRA TPIN is typically 10 digits
        if not re.match(r'^\d{10}$', v):
            raise ValueError('TPIN must be 10 digits')
        return v


class Step3LocationRequest(BaseModel):
    shop_id: str
    address: str
    city: str = "Lusaka"
    latitude: float
    longitude: float
    shopfront_photo_url: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    
    @validator('latitude')
    def validate_lat(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_lng(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v


class Step4FinancialRequest(BaseModel):
    shop_id: str
    settlement_type: str  # mobile_money, bank
    account_number: str
    account_name: Optional[str] = None
    bank_name: Optional[str] = None
    branch: Optional[str] = None
    
    @validator('settlement_type')
    def validate_settlement_type(cls, v):
        valid_types = ['mobile_money', 'bank']
        if v not in valid_types:
            raise ValueError(f'settlement_type must be one of: {valid_types}')
        return v
    
    @validator('account_number')
    def validate_mobile_money(cls, v, values):
        if values.get('settlement_type') == 'mobile_money':
            # Zambian Mobile Money: 10 digits, starts with 09x
            if not re.match(r'^09[5-7]\d{7}$', v):
                raise ValueError('Invalid Mobile Money number (must be 10 digits, start with 095/096/097)')
        return v


class Step5ReviewRequest(BaseModel):
    shop_id: str
    confirm_details_accurate: bool = True
    accept_terms: bool = True


# =============================================================================
# RESPONSE MODELS
# =============================================================================

class OnboardingStepResponse(BaseModel):
    success: bool
    shop_id: str
    current_stage: int
    next_stage: int
    message: str
    errors: Optional[list] = None


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/step-1", response_model=OnboardingStepResponse)
async def register_step_1_identity(request: Step1IdentityRequest):
    """
    Step 1: Identity - Basic shop and owner information.
    Creates the shop record in the database.
    """
    try:
        # Generate shop_id (would come from database insert)
        shop_id = f"shop_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # TODO: Insert into database
        # INSERT INTO Shops (shop_id, name, owner_name, phone_number, email, onboarding_stage)
        # VALUES (shop_id, shop_name, owner_name, phone_number, email, 1)
        
        return OnboardingStepResponse(
            success=True,
            shop_id=shop_id,
            current_stage=1,
            next_stage=2,
            message="Identity verified. Proceed to Legal Details.",
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/step-2", response_model=OnboardingStepResponse)
async def register_step_2_legal(request: Step2LegalRequest):
    """
    Step 2: Legal - Entity type, TPIN, PACRA number.
    Validates TPIN with ZRA VSDC API.
    """
    try:
        # Validate TPIN with ZRA
        tpin_valid = await _validate_tpin_with_zra(request.tpin)
        
        if not tpin_valid:
            return OnboardingStepResponse(
                success=False,
                shop_id=request.shop_id,
                current_stage=2,
                next_stage=2,
                message="Invalid TPIN. Please verify with ZRA.",
                errors=["TPIN validation failed with ZRA VSDC"],
            )
        
        # TODO: Update database
        # UPDATE Shops 
        # SET legal_type = legal_type, tpin = tpin, pacra_number = pacra_number,
        #     nrc_id_url = nrc_id_url, onboarding_stage = 2, zra_verified = TRUE
        # WHERE shop_id = shop_id
        
        return OnboardingStepResponse(
            success=True,
            shop_id=request.shop_id,
            current_stage=2,
            next_stage=3,
            message="ZRA TPIN verified. Proceed to Location.",
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/step-3", response_model=OnboardingStepResponse)
async def register_step_3_location(request: Step3LocationRequest):
    """
    Step 3: Location - Shop address, coordinates, photo.
    """
    try:
        # TODO: Update database with location
        # UPDATE Shops 
        # SET address = address, city = city, latitude = latitude, longitude = longitude,
        #     location = ST_Point(longitude, latitude)::geography,
        #     shopfront_photo_url = shopfront_photo_url, category = category,
        #     description = description, onboarding_stage = 3
        # WHERE shop_id = shop_id
        
        return OnboardingStepResponse(
            success=True,
            shop_id=request.shop_id,
            current_stage=3,
            next_stage=4,
            message="Location saved. Proceed to Financial Setup.",
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/step-4", response_model=OnboardingStepResponse)
async def register_step_4_financial(request: Step4FinancialRequest):
    """
    Step 4: Financial - Settlement account details.
    Validates Mobile Money format.
    """
    try:
        # Build settlement details JSON
        settlement_details = {
            "type": request.settlement_type,
            "number": request.account_number,
            "name": request.account_name,
        }
        
        if request.settlement_type == "bank":
            settlement_details["bank_name"] = request.bank_name
            settlement_details["branch"] = request.branch
        
        # TODO: Encrypt and store in database
        # UPDATE Shops 
        # SET settlement = settlement_type, 
        #     settlement_account_details = encrypt(settlement_details),
        #     onboarding_stage = 4
        # WHERE shop_id = shop_id
        
        return OnboardingStepResponse(
            success=True,
            shop_id=request.shop_id,
            current_stage=4,
            next_stage=5,
            message="Financial details saved. Proceed to Review.",
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/step-5", response_model=OnboardingStepResponse)
async def register_step_5_review(request: Step5ReviewRequest):
    """
    Step 5: Review - Submit for admin approval.
    Triggers admin notification.
    """
    try:
        if not request.confirm_details_accurate:
            raise HTTPException(status_code=400, detail="Please confirm details are accurate")
        
        if not request.accept_terms:
            raise HTTPException(status_code=400, detail="Please accept terms and conditions")
        
        # TODO: Update database
        # UPDATE Shops 
        # SET onboarding_stage = 5
        # WHERE shop_id = shop_id
        
        # Trigger admin notification
        await _notify_admin_new_shop_pending(request.shop_id)
        
        return OnboardingStepResponse(
            success=True,
            shop_id=request.shop_id,
            current_stage=5,
            next_stage=5,
            message="Application submitted! Our team will review and approve within 24 hours.",
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/status/{shop_id}")
async def get_onboarding_status(shop_id: str):
    """Get current onboarding status and stage."""
    # TODO: Query database
    
    return {
        "shop_id": shop_id,
        "current_stage": 1,
        "is_verified": False,
        "stages": {
            1: {"name": "Identity", "completed": False},
            2: {"name": "Legal", "completed": False},
            3: {"name": "Location", "completed": False},
            4: {"name": "Financial", "completed": False},
            5: {"name": "Review", "completed": False},
        },
    }


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

async def _validate_tpin_with_zra(tpin: str) -> bool:
    """
    Validate TPIN with ZRA VSDC API.
    CRITICAL: Calls initialize_vsdc function to verify taxpayer registration.
    """
    try:
        # Import the Smart Invoice API fiscalizer
        from services.smart_invoice_api import initialize_vsdc
        
        # Call ZRA VSDC to validate TPIN
        result = await initialize_vsdc(
            tpin=tpin,
            bhf_id='00',  # Default branch HQ
            dvc_srl_no=os.getenv('ZRA_DEVICE_SERIAL', ''),
        )
        
        # Check ZRA result codes
        # 000 = Success, 001 = Already initialized (valid)
        result_code = result.get('resultCd', '999')
        
        if result_code in ['000', '001']:
            print(f"[ZRA] TPIN {tpin} validated successfully (code: {result_code})")
            return True
        else:
            print(f"[ZRA] TPIN {tpin} validation failed (code: {result_code})")
            return False
        
    except ImportError:
        # Fallback: If smart_invoice_api not available, accept valid format
        print(f"[ZRA] Warning: smart_invoice_api not available, using format validation only")
        return len(tpin) == 10 and tpin.isdigit()
        
    except Exception as e:
        print(f"[ZRA ERROR] TPIN validation failed: {e}")
        return False


async def _notify_admin_new_shop_pending(shop_id: str):
    """
    Send notification to admin dashboard about new shop pending review.
    """
    try:
        # TODO: Send to admin notification service
        # POST /internal/admin/notifications
        # { type: "NEW_SHOP_PENDING", shop_id: shop_id }
        
        print(f"[ADMIN] New shop pending review: {shop_id}")
        
        # Could also send email/SMS to admin
        # from services.notification_service import send_admin_email
        # await send_admin_email(
        #     subject="New Shop Pending Review",
        #     body=f"Shop {shop_id} has completed onboarding and is awaiting approval."
        # )
        
    except Exception as e:
        print(f"[ADMIN NOTIFICATION ERROR] {e}")
