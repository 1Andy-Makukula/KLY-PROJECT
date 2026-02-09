"""
=============================================================================
KithLy Global Protocol - AGENTS UCP (Phase V Step 2)
agents_ucp.py - Universal Commerce Protocol for AI Agent Discovery
=============================================================================

Optimized for LLM Token Efficiency: Clean, flat JSON structures.
"""

from fastapi import APIRouter, Query
from typing import Optional, List
from datetime import datetime
import re

from services.currency_oracle import get_currency_oracle

router = APIRouter(prefix="/agents", tags=["AI Agents"])


# =============================================================================
# AI INSTRUCTIONS - Rules of Engagement
# =============================================================================

AI_SYSTEM_INSTRUCTIONS = """
You are interacting with the KithLy Global Gifting Protocol API.

RULES OF ENGAGEMENT:
1. Always verify shop has valid ZRA TPIN before recommending products
2. Quote prices in user's preferred currency (GBP/USD) with ZMW equivalent
3. Warn users about 1.5% volatility buffer on FX rates
4. Delivery is only available in Zambia (Lusaka, Kitwe, Ndola, Livingstone)
5. All transactions are ZRA tax-compliant with fiscal receipt
6. Payment via Stripe (GBP/USD) disbursed via Flutterwave (ZMW Mobile Money)

RESPONSE FORMAT:
- Keep responses concise for token efficiency
- Use product SKU IDs when referring to specific items
- Always include both local (ZMW) and foreign (GBP/USD) prices

EXAMPLE QUERIES:
- "Food under £10 in Lusaka" -> Use /search-gifts?max_price_gbp=10&city=Lusaka
- "Medicine for my grandmother" -> Use /search-gifts?query=medicine&city=Lusaka
- "How much is K150 in pounds?" -> Use /pricing/calculate with base_zmw=150
"""


@router.get("/ai-instructions")
async def get_ai_instructions():
    """
    System instructions for AI agents.
    Provides rules of engagement and API usage guidance.
    """
    return {
        "instructions": AI_SYSTEM_INSTRUCTIONS.strip(),
        "version": "1.0",
        "updated": "2026-02-09"
    }


# =============================================================================
# SEARCH GIFTS - Natural Language Product Discovery
# =============================================================================

# Mock product catalog (would query database)
PRODUCT_CATALOG = [
    {"sku": "SKU-FOOD-001", "name": "Coca-Cola 2L", "shop": "Shoprite Manda Hill", "city": "Lusaka", "zmw": 45, "category": "beverages", "zra_verified": True},
    {"sku": "SKU-FOOD-002", "name": "White Bread Loaf", "shop": "Shoprite Manda Hill", "city": "Lusaka", "zmw": 32, "category": "bakery", "zra_verified": True},
    {"sku": "SKU-FOOD-003", "name": "5kg Mealie Meal", "shop": "Shoprite Manda Hill", "city": "Lusaka", "zmw": 120, "category": "groceries", "zra_verified": True},
    {"sku": "SKU-FOOD-004", "name": "Cooking Oil 2L", "shop": "Shoprite Manda Hill", "city": "Lusaka", "zmw": 78, "category": "groceries", "zra_verified": True},
    {"sku": "SKU-MED-001", "name": "Paracetamol 500mg", "shop": "Rhodes Park Pharmacy", "city": "Lusaka", "zmw": 28, "category": "medicine", "zra_verified": True},
    {"sku": "SKU-MED-002", "name": "Vitamin C 1000mg", "shop": "Rhodes Park Pharmacy", "city": "Lusaka", "zmw": 95, "category": "medicine", "zra_verified": True},
    {"sku": "SKU-HW-001", "name": "Hammer 500g", "shop": "Chilenje Hardware", "city": "Lusaka", "zmw": 85, "category": "tools", "zra_verified": True},
    {"sku": "SKU-HW-002", "name": "Screwdriver Set", "shop": "Chilenje Hardware", "city": "Lusaka", "zmw": 65, "category": "tools", "zra_verified": True},
]

# Category keywords for natural language parsing
CATEGORY_KEYWORDS = {
    "food": ["food", "groceries", "eat", "meal", "bread", "mealie", "cooking"],
    "beverages": ["drink", "beverage", "cola", "soda", "water", "juice"],
    "medicine": ["medicine", "med", "pharmacy", "health", "paracetamol", "vitamin", "sick"],
    "tools": ["hardware", "tool", "hammer", "screwdriver", "fix", "repair"],
}


def parse_natural_query(query: str) -> dict:
    """Parse natural language query into structured filters."""
    query_lower = query.lower()
    result = {"keywords": [], "category": None, "max_price": None}
    
    # Extract category
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(kw in query_lower for kw in keywords):
            result["category"] = category
            break
    
    # Extract price limit (e.g., "under £10", "less than $20")
    price_match = re.search(r'under\s*[£$]?(\d+)|less than\s*[£$]?(\d+)|below\s*[£$]?(\d+)', query_lower)
    if price_match:
        result["max_price"] = float(price_match.group(1) or price_match.group(2) or price_match.group(3))
    
    # Extract keywords
    result["keywords"] = [w for w in query_lower.split() if len(w) > 2]
    
    return result


@router.get("/search-gifts")
async def search_gifts(
    query: str = Query("", description="Natural language search query"),
    max_price_gbp: Optional[float] = Query(None, description="Maximum price in GBP"),
    max_price_usd: Optional[float] = Query(None, description="Maximum price in USD"),
    city: str = Query("Lusaka", description="Delivery city"),
    category: Optional[str] = Query(None, description="Product category"),
    limit: int = Query(10, ge=1, le=20)
):
    """
    Search for giftable products using natural language.
    
    Examples:
    - "Food under £10 in Lusaka"
    - "Medicine for grandmother"
    - "Tools for home repair"
    
    Returns flat JSON optimized for LLM token efficiency.
    """
    oracle = get_currency_oracle()
    
    # Parse natural language query
    parsed = parse_natural_query(query)
    effective_category = category or parsed.get("category")
    effective_max_price = max_price_gbp or parsed.get("max_price")
    
    results = []
    
    for product in PRODUCT_CATALOG:
        # City filter
        if product["city"].lower() != city.lower():
            continue
        
        # Category filter
        if effective_category and product["category"] != effective_category:
            continue
        
        # ZRA verification check
        if not product["zra_verified"]:
            continue
        
        # Get prices
        gbp_price = await oracle.calculate_final_price(product["zmw"], "GBP")
        usd_price = await oracle.calculate_final_price(product["zmw"], "USD")
        
        # Price filter
        if effective_max_price and gbp_price.gbp and gbp_price.gbp > effective_max_price:
            continue
        if max_price_usd and usd_price.usd and usd_price.usd > max_price_usd:
            continue
        
        # Flat JSON structure for token efficiency
        results.append({
            "sku": product["sku"],
            "name": product["name"],
            "shop": product["shop"],
            "city": product["city"],
            "zmw": product["zmw"],
            "gbp": gbp_price.gbp,
            "usd": usd_price.usd,
            "zra_ok": product["zra_verified"],
        })
    
    # Sort by price
    results.sort(key=lambda x: x["gbp"] or 0)
    
    return {
        "query": query,
        "city": city,
        "count": len(results[:limit]),
        "results": results[:limit],
        "rates": {
            "zmw_gbp": round(await oracle.get_rate("ZMW", "GBP"), 4),
            "zmw_usd": round(await oracle.get_rate("ZMW", "USD"), 4),
        },
    }


# =============================================================================
# AGENT-INITIATED TRANSACTION
# =============================================================================

@router.post("/initiate-gift")
async def agent_initiate_gift(
    sku: str,
    receiver_phone: str,
    receiver_name: str,
    sender_currency: str = "GBP"
):
    """
    Initiate a gift transaction from an AI Agent.
    Creates transaction with status 150 (AGENT_INITIATED).
    
    Returns flat JSON with transaction details.
    """
    # Find product
    product = next((p for p in PRODUCT_CATALOG if p["sku"] == sku), None)
    if not product:
        return {"error": "Product not found", "sku": sku}
    
    # Calculate price
    oracle = get_currency_oracle()
    price = await oracle.calculate_final_price(product["zmw"], sender_currency)
    
    # Create transaction (would call C++ core)
    tx_id = f"tx_{datetime.now().strftime('%Y%m%d%H%M%S')}_{sku[-3:]}"
    
    return {
        "tx_id": tx_id,
        "status": 150,
        "status_name": "AGENT_INITIATED",
        "sku": sku,
        "product": product["name"],
        "shop": product["shop"],
        "receiver": receiver_name,
        "phone": receiver_phone,
        "zmw": product["zmw"],
        sender_currency.lower(): getattr(price, sender_currency.lower()),
        "zra_ready": product["zra_verified"],
    }
