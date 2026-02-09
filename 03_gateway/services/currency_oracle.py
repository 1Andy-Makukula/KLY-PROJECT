"""
=============================================================================
KithLy Global Protocol - CURRENCY ORACLE & FEE CALCULATOR (Phase V)
currency_oracle.py - Aeronautical Grade Pricing Engine
=============================================================================

Implements the complete pricing pipeline:
  Step A: Shop Base Price (ZMW)
  Step B: + Flutterwave Disbursement Fee (2%)
  Step C: + KithLy Protocol Fee (margin)
  Step D: Convert to GBP/USD using live rate
  Step E: + Stripe Intake Fee (2.9% + 30p)
  Step F: + 1.5% Volatility Buffer (protection for 10-min payment window)

Caching: 10-minute cache to avoid excessive API calls.
"""

import os
import time
from typing import Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime
import httpx
from dataclasses import dataclass

# Configuration
FIXER_API_KEY = os.getenv("FIXER_API_KEY", "")
EXCHANGE_RATE_API_KEY = os.getenv("EXCHANGE_RATE_API_KEY", "")

# Fee Configuration (The "Hard" Math)
FLUTTERWAVE_FEE_PERCENT = 2.0       # Step B: Disbursement fee
KITHLY_PROTOCOL_FEE_PERCENT = 3.0   # Step C: KithLy margin
STRIPE_PERCENT_FEE = 2.9            # Step E: Stripe percentage
STRIPE_FIXED_FEE_GBP = 0.30         # Step E: Stripe fixed fee (30p)
STRIPE_FIXED_FEE_USD = 0.30         # Step E: Stripe fixed fee (30c)
VOLATILITY_BUFFER_PERCENT = 1.5    # Step F: FX protection

# Cache Configuration
CACHE_TTL_SECONDS = 600  # 10 minutes


class PriceResult(BaseModel):
    """Clean JSON output for calculated price."""
    zmw: float
    gbp: Optional[float] = None
    usd: Optional[float] = None
    rate: float
    buffer_applied: bool
    breakdown: Dict[str, float]
    timestamp: str


@dataclass
class CachedRate:
    """Cached exchange rate entry."""
    rate: float
    fetched_at: float  # Unix timestamp
    
    @property
    def is_valid(self) -> bool:
        return time.time() - self.fetched_at < CACHE_TTL_SECONDS
    
    @property
    def age_seconds(self) -> float:
        return time.time() - self.fetched_at


class CurrencyOracle:
    """
    Currency oracle with 10-minute cache and multi-provider fallback.
    """
    
    # Rate cache: {currency_pair: CachedRate}
    _cache: Dict[str, CachedRate] = {}
    
    # Fallback rates (updated monthly as backup)
    _fallback_rates = {
        "ZMW_USD": 0.037,   # 1 ZMW = 0.037 USD (approx 27 ZMW per USD)
        "ZMW_GBP": 0.029,   # 1 ZMW = 0.029 GBP (approx 34 ZMW per GBP)
        "ZMW_EUR": 0.034,   # 1 ZMW = 0.034 EUR
        "USD_ZMW": 27.0,
        "GBP_ZMW": 34.5,
        "EUR_ZMW": 29.5,
    }
    
    def __init__(self):
        self.last_fetch_error: Optional[str] = None
    
    # =========================================================================
    # RATE FETCHING WITH CACHE
    # =========================================================================
    
    async def get_rate(self, from_currency: str, to_currency: str) -> float:
        """Get exchange rate with 10-minute cache."""
        cache_key = f"{from_currency}_{to_currency}"
        
        # Check cache first
        if cache_key in self._cache and self._cache[cache_key].is_valid:
            return self._cache[cache_key].rate
        
        # Fetch fresh rate
        rate = await self._fetch_live_rate(from_currency, to_currency)
        
        # Update cache
        self._cache[cache_key] = CachedRate(rate=rate, fetched_at=time.time())
        
        return rate
    
    async def _fetch_live_rate(self, from_currency: str, to_currency: str) -> float:
        """Fetch live rate from external APIs with fallback."""
        
        # Try ExchangeRate-API first (free tier available)
        if EXCHANGE_RATE_API_KEY:
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(
                        f"https://v6.exchangerate-api.com/v6/{EXCHANGE_RATE_API_KEY}/pair/{from_currency}/{to_currency}",
                        timeout=5.0
                    )
                    data = response.json()
                    if data.get("result") == "success":
                        self.last_fetch_error = None
                        return data["conversion_rate"]
            except Exception as e:
                self.last_fetch_error = f"ExchangeRate-API: {e}"
        
        # Try Fixer.io as backup
        if FIXER_API_KEY:
            try:
                async with httpx.AsyncClient() as client:
                    # Fixer free tier only supports EUR base
                    response = await client.get(
                        "http://data.fixer.io/api/latest",
                        params={
                            "access_key": FIXER_API_KEY,
                            "symbols": f"{from_currency},{to_currency}",
                        },
                        timeout=5.0
                    )
                    data = response.json()
                    if data.get("success"):
                        rates = data["rates"]
                        # Calculate cross rate via EUR
                        from_rate = rates.get(from_currency, 1.0)
                        to_rate = rates.get(to_currency, 1.0)
                        self.last_fetch_error = None
                        return to_rate / from_rate
            except Exception as e:
                self.last_fetch_error = f"Fixer.io: {e}"
        
        # Fallback to static rates
        cache_key = f"{from_currency}_{to_currency}"
        if cache_key in self._fallback_rates:
            return self._fallback_rates[cache_key]
        
        # Calculate via USD if direct rate not available
        try:
            to_usd = self._fallback_rates.get(f"{from_currency}_USD", 1.0)
            from_usd = self._fallback_rates.get(f"USD_{to_currency}", 1.0)
            return to_usd * from_usd
        except:
            return 1.0
    
    # =========================================================================
    # THE "HARD" MATH - AERONAUTICAL GRADE CALCULATION
    # =========================================================================
    
    async def calculate_final_price(
        self,
        base_zmw: float,
        target_currency: str = "GBP"
    ) -> PriceResult:
        """
        Calculate final price with all fees applied.
        
        Step A: Start with Shop Price (base_zmw)
        Step B: Add Flutterwave Disbursement Fee (2%)
        Step C: Add KithLy Protocol Fee (margin)
        Step D: Convert to target currency using live rate
        Step E: Add Stripe Intake Fee (2.9% + fixed)
        Step F: Add 1.5% Volatility Buffer
        """
        
        breakdown = {}
        
        # Step A: Base shop price
        step_a = base_zmw
        breakdown["step_a_base_zmw"] = step_a
        
        # Step B: Add Flutterwave fee (2% of base)
        flutterwave_fee = step_a * (FLUTTERWAVE_FEE_PERCENT / 100)
        step_b = step_a + flutterwave_fee
        breakdown["step_b_flutterwave_fee"] = flutterwave_fee
        breakdown["step_b_subtotal_zmw"] = step_b
        
        # Step C: Add KithLy Protocol fee
        kithly_fee = step_b * (KITHLY_PROTOCOL_FEE_PERCENT / 100)
        step_c = step_b + kithly_fee
        breakdown["step_c_kithly_fee"] = kithly_fee
        breakdown["step_c_subtotal_zmw"] = step_c
        
        # Step D: Convert to target currency
        rate = await self.get_rate("ZMW", target_currency)
        step_d = step_c * rate
        breakdown["step_d_rate_applied"] = rate
        breakdown["step_d_converted"] = step_d
        
        # Step E: Add Stripe fees (2.9% + fixed)
        stripe_fixed = STRIPE_FIXED_FEE_GBP if target_currency == "GBP" else STRIPE_FIXED_FEE_USD
        # Stripe fee comes off what we collect, so we need to gross up
        # Final = (Net + Fixed) / (1 - 0.029)
        step_e = (step_d + stripe_fixed) / (1 - STRIPE_PERCENT_FEE / 100)
        stripe_fee = step_e - step_d
        breakdown["step_e_stripe_fee"] = stripe_fee
        breakdown["step_e_subtotal"] = step_e
        
        # Step F: Add volatility buffer (1.5%)
        buffer = step_e * (VOLATILITY_BUFFER_PERCENT / 100)
        step_f = step_e + buffer
        breakdown["step_f_volatility_buffer"] = buffer
        breakdown["step_f_final"] = step_f
        
        # Round to 2 decimal places for currency
        final_amount = round(step_f, 2)
        
        # Build result
        result = PriceResult(
            zmw=base_zmw,
            rate=round(rate, 6),
            buffer_applied=True,
            breakdown={k: round(v, 4) for k, v in breakdown.items()},
            timestamp=datetime.utcnow().isoformat()
        )
        
        if target_currency == "GBP":
            result.gbp = final_amount
        elif target_currency == "USD":
            result.usd = final_amount
        
        return result
    
    async def calculate_multi_currency(self, base_zmw: float) -> Dict[str, Any]:
        """Calculate final prices in both GBP and USD."""
        gbp_result = await self.calculate_final_price(base_zmw, "GBP")
        usd_result = await self.calculate_final_price(base_zmw, "USD")
        
        return {
            "zmw": base_zmw,
            "gbp": gbp_result.gbp,
            "usd": usd_result.usd,
            "rates": {
                "ZMW_GBP": gbp_result.rate,
                "ZMW_USD": usd_result.rate,
            },
            "buffer_applied": True,
            "breakdown_gbp": gbp_result.breakdown,
            "breakdown_usd": usd_result.breakdown,
            "timestamp": datetime.utcnow().isoformat(),
        }
    
    # =========================================================================
    # CACHE MANAGEMENT
    # =========================================================================
    
    def get_cache_status(self) -> Dict[str, Any]:
        """Get current cache status."""
        return {
            "entries": len(self._cache),
            "rates": {
                key: {
                    "rate": cached.rate,
                    "age_seconds": round(cached.age_seconds, 1),
                    "valid": cached.is_valid,
                }
                for key, cached in self._cache.items()
            },
            "ttl_seconds": CACHE_TTL_SECONDS,
            "last_error": self.last_fetch_error,
        }
    
    def invalidate_cache(self):
        """Force cache invalidation."""
        self._cache.clear()


# Singleton instance
_oracle: Optional[CurrencyOracle] = None

def get_currency_oracle() -> CurrencyOracle:
    """Get singleton oracle instance."""
    global _oracle
    if _oracle is None:
        _oracle = CurrencyOracle()
    return _oracle


# =============================================================================
# ZONE-BASED DELIVERY PRICING (Phase V)
# =============================================================================

from math import radians, cos, sin, asin, sqrt
from typing import Tuple

@dataclass(frozen=True)
class DeliveryZone:
    """Delivery zone definition"""
    name: str
    min_km: float
    max_km: float
    fee_zmw: int


DELIVERY_ZONES = [
    DeliveryZone(name="A", min_km=0, max_km=5, fee_zmw=50),
    DeliveryZone(name="B", min_km=5, max_km=15, fee_zmw=100),
    DeliveryZone(name="C", min_km=15, max_km=float('inf'), fee_zmw=220),
]


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate great-circle distance between two points in kilometers.
    Uses the Haversine formula.
    """
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    c = 2 * asin(sqrt(a))
    return 6371 * c  # Earth's radius in km


def get_zone_price(km: float) -> Tuple[int, str]:
    """
    Get delivery fee and zone based on distance.
    
    Returns:
        Tuple of (fee in ZMW, zone name)
        
    Examples:
        >>> get_zone_price(3.5)
        (50, 'A')
        >>> get_zone_price(10.0)
        (100, 'B')
        >>> get_zone_price(25.0)
        (220, 'C')
    """
    for zone in DELIVERY_ZONES:
        if zone.min_km <= km < zone.max_km:
            return (zone.fee_zmw, zone.name)
    return (220, 'C')


def calculate_delivery_fee(
    shop_lat: float, shop_lon: float,
    recipient_lat: float, recipient_lon: float
) -> dict:
    """Calculate complete delivery pricing information."""
    distance_km = haversine_distance(shop_lat, shop_lon, recipient_lat, recipient_lon)
    fee_zmw, zone = get_zone_price(distance_km)
    
    return {
        "distance_km": round(distance_km, 2),
        "zone": zone,
        "fee_zmw": fee_zmw,
        "formatted_fee": f"K{fee_zmw}",
        "zone_description": {"A": "Local (0-5km)", "B": "Near (5-15km)", "C": "Extended (15km+)"}.get(zone)
    }


def compare_routes(
    original_shop_lat: float, original_shop_lon: float,
    alternative_shop_lat: float, alternative_shop_lon: float,
    recipient_lat: float, recipient_lon: float
) -> dict:
    """Compare pricing between original and alternative shop routes."""
    original = calculate_delivery_fee(original_shop_lat, original_shop_lon, recipient_lat, recipient_lon)
    alternative = calculate_delivery_fee(alternative_shop_lat, alternative_shop_lon, recipient_lat, recipient_lon)
    
    distance_diff = alternative["distance_km"] - original["distance_km"]
    fee_diff = alternative["fee_zmw"] - original["fee_zmw"]
    
    return {
        "original_route": original,
        "alternative_route": alternative,
        "distance_diff_km": round(distance_diff, 2),
        "fee_diff_zmw": fee_diff,
        "formatted_distance_diff": f"{'+' if distance_diff >= 0 else ''}{round(distance_diff, 1)}km",
        "formatted_fee_diff": f"K{'+' if fee_diff >= 0 else ''}{fee_diff}" if fee_diff != 0 else "K0",
    }

