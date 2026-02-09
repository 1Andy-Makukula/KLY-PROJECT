"""
=============================================================================
KithLy Global Protocol - ZRA FISCALIZER (Phase III)
zra_fiscalizer.py - ZRA Smart Invoice VSDC Integration
=============================================================================

Bridges KithLy Gateway with ZRA Smart Invoice API.
Implements call_vsdc, sync requests, and exponential backoff.
"""

import os
import json
import math
import requests
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from pydantic import BaseModel

# Configuration
ZRA_BASE_URL = os.getenv("ZRA_VSDC_URL", "http://localhost:8080/vsdc")
ZRA_TIMEOUT = int(os.getenv("ZRA_TIMEOUT", "10"))

# Status codes
STATUS_COMPLETED = 400
STATUS_HELD_FOR_REVIEW = 800


class ZRASettings(BaseModel):
    """ZRA VSDC connection settings."""
    base_url: str = ZRA_BASE_URL
    timeout: int = ZRA_TIMEOUT
    tpin: str = ""
    bhf_id: str = "000"  # Default branch


class ZRAResponse(BaseModel):
    """Response from ZRA VSDC API."""
    success: bool
    result_code: Optional[str] = None
    result_msg: Optional[str] = None
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class SyncRequest(BaseModel):
    """Sync request for retry queue."""
    tx_id: str
    endpoint: str
    payload: Dict[str, Any]
    attempt_count: int = 0
    max_attempts: int = 5
    next_retry_at: Optional[datetime] = None


def call_vsdc(endpoint: str, data: Dict[str, Any], settings: ZRASettings) -> ZRAResponse:
    """
    Call ZRA VSDC API endpoint.
    Uses timeout=(connect, read) pattern for reliability.
    """
    try:
        r = requests.post(
            f"{settings.base_url}{endpoint}",
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=(settings.timeout, 30)  # Connect/Read timeout
        )
        
        response_data = r.json()
        
        return ZRAResponse(
            success=response_data.get("resultCd") in ["000", "001"],
            result_code=response_data.get("resultCd"),
            result_msg=response_data.get("resultMsg"),
            data=response_data.get("data")
        )
        
    except json.decoder.JSONDecodeError as e:
        return ZRAResponse(
            success=False,
            error=f"JSON Decode Error: {str(e)}"
        )
    except requests.exceptions.Timeout:
        return ZRAResponse(
            success=False,
            error="Connection Timeout"
        )
    except requests.exceptions.ConnectionError:
        return ZRAResponse(
            success=False,
            error="Connection Error"
        )
    except Exception as e:
        return ZRAResponse(
            success=False,
            error=f"Exception: {str(e)}"
        )


def calculate_backoff_delay(attempt: int, base_delay: int = 60) -> int:
    """
    Calculate exponential backoff delay in seconds.
    Formula: base_delay * 2^attempt (capped at 24 hours)
    """
    max_delay = 86400  # 24 hours
    delay = base_delay * math.pow(2, attempt)
    return int(min(delay, max_delay))


def create_sync_request(
    tx_id: str,
    endpoint: str,
    payload: Dict[str, Any],
    attempt: int = 0
) -> SyncRequest:
    """
    Create a sync request for the retry queue.
    Calculates next retry time using exponential backoff.
    """
    delay_seconds = calculate_backoff_delay(attempt)
    next_retry = datetime.utcnow() + timedelta(seconds=delay_seconds)
    
    return SyncRequest(
        tx_id=tx_id,
        endpoint=endpoint,
        payload=payload,
        attempt_count=attempt,
        next_retry_at=next_retry
    )


def get_last_request_date() -> str:
    """Get formatted date for ZRA lastReqDt field."""
    return datetime.now().strftime("%Y%m%d%H%M%S")


def build_save_sales_payload(
    tx_id: str,
    tpin: str,
    bhf_id: str,
    total_amount: float,
    items: list = None
) -> Dict[str, Any]:
    """Build ZRA saveSales payload from extracted data."""
    return {
        "tpin": tpin,
        "bhfId": bhf_id,
        "orgInvcNo": 0,
        "cisInvcNo": tx_id[:20],  # Invoice number
        "custTpin": "",  # Anonymous for diaspora
        "salesTyCd": "N",  # Normal Sale
        "rcptTyCd": "S",  # Sales Invoice
        "pmtTyCd": "01",  # Cash/Electronic
        "salesSttsCd": "02",  # Approved
        "cfmDt": get_last_request_date(),
        "salesDt": datetime.now().strftime("%Y%m%d"),
        "totTaxAmt": round(total_amount * 0.16, 2),  # 16% VAT estimate
        "totAmt": total_amount,
        "lastReqDt": get_last_request_date(),
        "itemList": items or []
    }


async def fiscalize_gift_delivery(
    tx_id: str,
    extraction_data: Dict[str, Any],
    settings: ZRASettings = None
) -> Dict[str, Any]:
    """
    Main fiscalization function.
    Called after Gemini Vision extracts ZRA data.
    
    Returns:
        dict with status, zra_ref, and recommended_status
    """
    settings = settings or ZRASettings()
    
    # Build ZRA payload from extracted data
    zra_payload = build_save_sales_payload(
        tx_id=tx_id,
        tpin=extraction_data.get("tpin", settings.tpin),
        bhf_id=extraction_data.get("bhf_id", settings.bhf_id),
        total_amount=extraction_data.get("total_amount", 0)
    )
    
    # Call VSDC saveSales
    response = call_vsdc("/trnsSales/saveSales", zra_payload, settings)
    
    if response.success:
        return {
            "status": "SUCCESS",
            "zra_ref": response.data,
            "result_code": response.result_code,
            "recommended_status": STATUS_COMPLETED
        }
    
    # Connection error - queue for retry
    if response.error and "Connection" in response.error:
        sync_req = create_sync_request(tx_id, "/trnsSales/saveSales", zra_payload)
        return {
            "status": "RETRY_QUEUED",
            "error": response.error,
            "sync_request": sync_req.dict(),
            "recommended_status": STATUS_HELD_FOR_REVIEW
        }
    
    # Other error
    return {
        "status": "FAILED",
        "error": response.result_msg or response.error,
        "result_code": response.result_code,
        "recommended_status": STATUS_HELD_FOR_REVIEW
    }


async def initialize_vsdc(tpin: str, bhf_id: str = "000") -> ZRAResponse:
    """
    Initialize VSDC for a shop during onboarding.
    Validates that the TPIN is registered with ZRA.
    """
    settings = ZRASettings(tpin=tpin, bhf_id=bhf_id)
    
    payload = {
        "tpin": tpin,
        "bhfId": bhf_id,
        "lastReqDt": get_last_request_date()
    }
    
    return call_vsdc("/initializer/selectInitInfo", payload, settings)
