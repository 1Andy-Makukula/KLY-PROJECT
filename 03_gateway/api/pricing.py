"""
=============================================================================
KithLy Global Protocol - PRICING API (Phase V)
pricing.py - Currency Oracle HTTP Endpoints
=============================================================================
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from services.currency_oracle import get_currency_oracle, PriceResult

router = APIRouter(prefix="/pricing", tags=["Pricing"])


class PriceRequest(BaseModel):
    base_zmw: float
    target_currency: str = "GBP"


class MultiPriceRequest(BaseModel):
    base_zmw: float


@router.post("/calculate", response_model=PriceResult)
async def calculate_price(request: PriceRequest):
    """
    Calculate final price with all fees applied.
    
    Returns:
        { "zmw": 150, "gbp": 4.85, "rate": 0.029, "buffer_applied": true, ... }
    """
    oracle = get_currency_oracle()
    
    if request.base_zmw <= 0:
        raise HTTPException(status_code=400, detail="base_zmw must be positive")
    
    if request.target_currency not in ["GBP", "USD", "EUR"]:
        raise HTTPException(status_code=400, detail="target_currency must be GBP, USD, or EUR")
    
    result = await oracle.calculate_final_price(
        base_zmw=request.base_zmw,
        target_currency=request.target_currency
    )
    
    return result


@router.post("/calculate-multi")
async def calculate_multi_currency(request: MultiPriceRequest):
    """
    Calculate final prices in both GBP and USD.
    
    Returns:
        {
            "zmw": 150,
            "gbp": 4.85,
            "usd": 6.12,
            "rates": { "ZMW_GBP": 0.029, "ZMW_USD": 0.037 },
            "buffer_applied": true,
            ...
        }
    """
    oracle = get_currency_oracle()
    
    if request.base_zmw <= 0:
        raise HTTPException(status_code=400, detail="base_zmw must be positive")
    
    return await oracle.calculate_multi_currency(request.base_zmw)


@router.get("/rates")
async def get_current_rates():
    """Get current exchange rates (from cache if valid)."""
    oracle = get_currency_oracle()
    
    gbp_rate = await oracle.get_rate("ZMW", "GBP")
    usd_rate = await oracle.get_rate("ZMW", "USD")
    
    return {
        "ZMW_GBP": round(gbp_rate, 6),
        "ZMW_USD": round(usd_rate, 6),
        "cache_status": oracle.get_cache_status(),
    }


@router.post("/invalidate-cache")
async def invalidate_rate_cache():
    """Force refresh of cached exchange rates."""
    oracle = get_currency_oracle()
    oracle.invalidate_cache()
    
    return {"status": "cache_invalidated"}
