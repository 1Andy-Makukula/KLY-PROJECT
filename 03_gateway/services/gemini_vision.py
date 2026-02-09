"""
=============================================================================
KithLy Global Protocol - AI AUDITOR + ZRA FISCAL (Phase III)
gemini_vision.py - Gemini 1.5 Pro + ZRA VSDC Integration
=============================================================================
"""

import os
import json
import base64
import hashlib
from typing import Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

import google.generativeai as genai

from .zra_fiscalizer import fiscalize_gift_delivery, ZRASettings

# Configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL = "gemini-1.5-pro"

STATUS_COMPLETED = 400
STATUS_HELD_FOR_REVIEW = 800
CONFIDENCE_THRESHOLD = 0.85


class ZRAExtraction(BaseModel):
    """ZRA data extracted from receipt image."""
    tpin: Optional[str] = None
    bhf_id: Optional[str] = None
    date: Optional[str] = None
    total_amount: Optional[float] = None
    fiscal_code: Optional[str] = None


class AuditResult(BaseModel):
    """Result from AI Vision + ZRA Fiscalization."""
    match: bool
    zra_ref: Optional[str] = None
    tpin: Optional[str] = None
    bhf_id: Optional[str] = None
    date: Optional[str] = None
    total_amount: Optional[float] = None
    confidence: float
    zra_result_code: Optional[str] = None
    zra_status: Optional[str] = None
    recommended_status: int
    raw_response: Optional[str] = None


class GeminiVisionService:
    """AI Auditor + ZRA Fiscalizer using Gemini 1.5 Pro."""
    
    def __init__(self, api_key: str = GEMINI_API_KEY):
        if api_key:
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(GEMINI_MODEL)
        else:
            self.model = None

    async def extract_zra_data(self, image_bytes: bytes, expected_sku: str) -> Dict[str, Any]:
        """Extract ZRA-specific fields from receipt photo."""
        
        if not self.model:
            return {
                "match": True,
                "tpin": "1001234567",
                "bhf_id": "000",
                "date": datetime.now().strftime("%Y%m%d%H%M%S"),
                "total_amount": 50.00,
                "fiscal_code": "ZRA-MOCK-123",
                "confidence": 0.90
            }
        
        prompt = f"""You are the KithLy Auditor. Analyze this delivery receipt image.

1. Identify if the item matches SKU: {expected_sku}
2. Locate the ZRA Tax Receipt
3. Extract these specific ZRA fields:
   - TPIN (10-digit taxpayer ID)
   - Branch ID (bhfId, usually 3 digits like "000")
   - Date (format: YYYYMMDDHHMMSS)
   - Total Amount (numeric)
   - ZRA Fiscal Code

Rate your confidence from 0.0 to 1.0.

Output JSON only:
{{
    "match": bool,
    "tpin": string or null,
    "bhf_id": string or null,
    "date": string or null,
    "total_amount": float or null,
    "fiscal_code": string or null,
    "confidence": float
}}"""

        try:
            image_b64 = base64.b64encode(image_bytes).decode()
            response = self.model.generate_content([
                {"mime_type": "image/jpeg", "data": image_b64},
                prompt
            ])
            
            raw_text = response.text
            if "```json" in raw_text:
                raw_text = raw_text.split("```json")[1].split("```")[0]
            elif "```" in raw_text:
                raw_text = raw_text.split("```")[1].split("```")[0]
            
            return json.loads(raw_text.strip())
            
        except Exception as e:
            return {"error": str(e), "confidence": 0.0}

    async def verify_and_fiscalize(
        self,
        tx_id: str,
        image_bytes: bytes,
        expected_sku: str
    ) -> AuditResult:
        """
        Complete verification flow:
        Step A: Gemini extracts ZRA data
        Step B: Gateway calls saveSales
        Step C: If resultCd 000/001 → Success
        Step D: If Connection Error → Queue with backoff → Status 800
        """
        
        # Step A: AI Extraction
        extraction = await self.extract_zra_data(image_bytes, expected_sku)
        
        confidence = extraction.get("confidence", 0.0)
        
        # Low confidence → Hold for review
        if confidence < CONFIDENCE_THRESHOLD:
            return AuditResult(
                match=extraction.get("match", False),
                tpin=extraction.get("tpin"),
                bhf_id=extraction.get("bhf_id"),
                date=extraction.get("date"),
                total_amount=extraction.get("total_amount"),
                confidence=confidence,
                zra_status="SKIPPED_LOW_CONFIDENCE",
                recommended_status=STATUS_HELD_FOR_REVIEW,
                raw_response=str(extraction)
            )
        
        # Step B & C: Call ZRA VSDC
        fiscal_result = await fiscalize_gift_delivery(tx_id, extraction)
        
        return AuditResult(
            match=extraction.get("match", False),
            zra_ref=extraction.get("fiscal_code"),
            tpin=extraction.get("tpin"),
            bhf_id=extraction.get("bhf_id"),
            date=extraction.get("date"),
            total_amount=extraction.get("total_amount"),
            confidence=confidence,
            zra_result_code=fiscal_result.get("result_code"),
            zra_status=fiscal_result.get("status"),
            recommended_status=fiscal_result.get("recommended_status", STATUS_HELD_FOR_REVIEW),
            raw_response=str(fiscal_result)
        )

    async def analyze_delivery_proof(
        self,
        image_bytes: bytes,
        expected_sku: str
    ) -> AuditResult:
        """Legacy method - calls verify_and_fiscalize."""
        return await self.verify_and_fiscalize("temp_tx", image_bytes, expected_sku)


# Singleton
_service: Optional[GeminiVisionService] = None

def get_vision_service() -> GeminiVisionService:
    global _service
    if _service is None:
        _service = GeminiVisionService()
    return _service
