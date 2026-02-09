"""
=============================================================================
KithLy Global Protocol - ANALYTICS ENGINE (Phase V)
analytics.py - Shop Performance Scoring & Tier Calculation
=============================================================================

Calculates shop performance scores (0-100) based on:
- Completion Rate
- ZRA Compliance
- Customer Ratings
- Response Time
"""

from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import asyncpg
import os


# =============================================================================
# TIER DEFINITIONS
# =============================================================================

@dataclass
class TierThreshold:
    """Tier qualification criteria"""
    name: str
    min_score: float
    max_score: float
    benefits: List[str]


TIER_THRESHOLDS = [
    TierThreshold(
        name="select",
        min_score=85,
        max_score=100,
        benefits=["Priority placement", "Lower fees", "Premium badge", "Dedicated support"]
    ),
    TierThreshold(
        name="verified", 
        min_score=65,
        max_score=84.99,
        benefits=["ZRA verified badge", "Standard fees", "Featured in category"]
    ),
    TierThreshold(
        name="independent",
        min_score=40,
        max_score=64.99,
        benefits=["Basic listing", "Standard fees"]
    ),
    TierThreshold(
        name="sandbox",
        min_score=0,
        max_score=39.99,
        benefits=["Training mode", "Limited visibility"]
    ),
]


# =============================================================================
# SCORING WEIGHTS
# =============================================================================

WEIGHTS = {
    "completion_rate": 0.35,      # 35% - Orders completed successfully
    "zra_compliance": 0.25,       # 25% - Tax compliance status
    "customer_rating": 0.25,      # 25% - Average customer rating
    "response_time": 0.15,        # 15% - Order acceptance speed
}


# =============================================================================
# ANALYTICS ENGINE
# =============================================================================

class AnalyticsEngine:
    """Shop performance analytics and tier calculation."""
    
    def __init__(self, db_url: Optional[str] = None):
        self.db_url = db_url or os.getenv("DATABASE_URL", "postgresql://localhost/kithly")
        self._pool = None
    
    async def _get_pool(self):
        if self._pool is None:
            self._pool = await asyncpg.create_pool(self.db_url)
        return self._pool
    
    async def calculate_score(self, shop_id: str) -> Dict[str, Any]:
        """
        Calculate shop performance score and tier.
        
        Returns:
            Dict with score (0-100), tier, and breakdown
        """
        pool = await self._get_pool()
        
        async with pool.acquire() as conn:
            # Get completion rate (last 30 days)
            completion_data = await self._get_completion_rate(conn, shop_id)
            
            # Get ZRA compliance status
            zra_data = await self._get_zra_compliance(conn, shop_id)
            
            # Get customer rating
            rating_data = await self._get_customer_rating(conn, shop_id)
            
            # Get response time
            response_data = await self._get_response_time(conn, shop_id)
        
        # Calculate weighted score
        scores = {
            "completion_rate": completion_data["score"],
            "zra_compliance": zra_data["score"],
            "customer_rating": rating_data["score"],
            "response_time": response_data["score"],
        }
        
        final_score = sum(
            scores[key] * WEIGHTS[key]
            for key in WEIGHTS.keys()
        )
        
        # Determine tier
        tier = self._get_tier(final_score)
        
        # Update shop record
        await self._update_shop_score(shop_id, final_score, tier)
        
        return {
            "shop_id": shop_id,
            "score": round(final_score, 2),
            "tier": tier,
            "breakdown": {
                "completion_rate": {
                    **completion_data,
                    "weight": WEIGHTS["completion_rate"]
                },
                "zra_compliance": {
                    **zra_data,
                    "weight": WEIGHTS["zra_compliance"]
                },
                "customer_rating": {
                    **rating_data,
                    "weight": WEIGHTS["customer_rating"]
                },
                "response_time": {
                    **response_data,
                    "weight": WEIGHTS["response_time"]
                },
            },
            "tier_benefits": self._get_tier_benefits(tier),
            "calculated_at": datetime.utcnow().isoformat(),
        }
    
    async def _get_completion_rate(self, conn, shop_id: str) -> Dict:
        """Calculate order completion rate (status 400 / total orders)."""
        try:
            result = await conn.fetchrow("""
                SELECT 
                    COUNT(*) FILTER (WHERE status_code = 400) as completed,
                    COUNT(*) as total
                FROM Global_Gifts
                WHERE shop_id = $1
                AND created_at > NOW() - INTERVAL '30 days'
            """, shop_id)
            
            total = result["total"] if result else 0
            completed = result["completed"] if result else 0
            
            if total == 0:
                return {"score": 50, "completed": 0, "total": 0, "rate": 0}
            
            rate = (completed / total) * 100
            # Score: 100 for 95%+ completion, linear scale down
            score = min(100, (rate / 95) * 100)
            
            return {
                "score": round(score, 2),
                "completed": completed,
                "total": total,
                "rate": round(rate, 2)
            }
        except Exception:
            return {"score": 50, "completed": 0, "total": 0, "rate": 0, "error": True}
    
    async def _get_zra_compliance(self, conn, shop_id: str) -> Dict:
        """Check ZRA verification status."""
        try:
            result = await conn.fetchrow("""
                SELECT is_verified, tpin, verified_at
                FROM Shops
                WHERE shop_id = $1
            """, shop_id)
            
            if not result:
                return {"score": 0, "verified": False, "tpin_present": False}
            
            is_verified = result["is_verified"]
            has_tpin = result["tpin"] is not None
            
            score = 100 if is_verified else (50 if has_tpin else 0)
            
            return {
                "score": score,
                "verified": is_verified,
                "tpin_present": has_tpin,
                "verified_at": result["verified_at"].isoformat() if result["verified_at"] else None
            }
        except Exception:
            return {"score": 50, "verified": False, "error": True}
    
    async def _get_customer_rating(self, conn, shop_id: str) -> Dict:
        """Get average customer rating."""
        try:
            result = await conn.fetchrow("""
                SELECT AVG(rating) as avg_rating, COUNT(*) as count
                FROM Reviews
                WHERE shop_id = $1
                AND created_at > NOW() - INTERVAL '90 days'
            """, shop_id)
            
            avg_rating = float(result["avg_rating"]) if result and result["avg_rating"] else 0
            count = result["count"] if result else 0
            
            # Score: rating out of 5, scaled to 100
            score = (avg_rating / 5) * 100 if avg_rating > 0 else 50
            
            return {
                "score": round(score, 2),
                "avg_rating": round(avg_rating, 2),
                "review_count": count
            }
        except Exception:
            return {"score": 50, "avg_rating": 0, "review_count": 0, "error": True}
    
    async def _get_response_time(self, conn, shop_id: str) -> Dict:
        """Calculate average order response time."""
        try:
            # For Baker's Protocol orders (Status 110 → 200)
            result = await conn.fetchrow("""
                SELECT AVG(
                    EXTRACT(EPOCH FROM (shop_accepted_at - created_at)) / 60
                ) as avg_minutes
                FROM Global_Gifts
                WHERE shop_id = $1
                AND shop_accepted_at IS NOT NULL
                AND created_at > NOW() - INTERVAL '30 days'
            """, shop_id)
            
            avg_minutes = float(result["avg_minutes"]) if result and result["avg_minutes"] else 30
            
            # Score: 100 for < 5 min, 0 for > 60 min
            if avg_minutes <= 5:
                score = 100
            elif avg_minutes >= 60:
                score = 0
            else:
                score = 100 - ((avg_minutes - 5) / 55 * 100)
            
            return {
                "score": round(score, 2),
                "avg_response_minutes": round(avg_minutes, 1)
            }
        except Exception:
            return {"score": 50, "avg_response_minutes": 30, "error": True}
    
    def _get_tier(self, score: float) -> str:
        """Determine tier based on score."""
        for tier in TIER_THRESHOLDS:
            if tier.min_score <= score <= tier.max_score:
                return tier.name
        return "sandbox"
    
    def _get_tier_benefits(self, tier_name: str) -> List[str]:
        """Get benefits for a tier."""
        for tier in TIER_THRESHOLDS:
            if tier.name == tier_name:
                return tier.benefits
        return []
    
    async def _update_shop_score(self, shop_id: str, score: float, tier: str):
        """Update shop record with new score and tier."""
        try:
            pool = await self._get_pool()
            async with pool.acquire() as conn:
                await conn.execute("""
                    UPDATE Shops
                    SET performance_score = $1, tier = $2
                    WHERE shop_id = $3
                """, score, tier, shop_id)
        except Exception as e:
            print(f"[ANALYTICS] Failed to update shop score: {e}")
    
    async def get_tier_leaderboard(self, tier: str = "select", limit: int = 10) -> List[Dict]:
        """Get top shops in a tier."""
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            results = await conn.fetch("""
                SELECT shop_id, name, performance_score, tier
                FROM Shops
                WHERE tier = $1
                ORDER BY performance_score DESC
                LIMIT $2
            """, tier, limit)
            
            return [dict(r) for r in results]


# =============================================================================
# SINGLETON & HELPER
# =============================================================================

_engine: Optional[AnalyticsEngine] = None

def get_analytics_engine() -> AnalyticsEngine:
    """Get singleton analytics engine."""
    global _engine
    if _engine is None:
        _engine = AnalyticsEngine()
    return _engine


async def calculate_shop_score(shop_id: str) -> Dict[str, Any]:
    """Quick access function to calculate shop score."""
    engine = get_analytics_engine()
    return await engine.calculate_score(shop_id)
