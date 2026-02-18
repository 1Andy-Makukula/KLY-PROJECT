"""
=============================================================================
KithLy Global Protocol - PAYMENTS AP2 (Phase V)
payments_ap2.py - Stripe + Flutterwave Financial Bridge with Webhooks
=============================================================================

Server-to-server webhooks are "The Truth" - never trust client-side success.
"""

import os
import hmac
import hashlib
import json
import logging
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Request, Header
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from services.database import get_db
from services.models import Transaction

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/payments", tags=["Payments"])

# Configuration
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")
FLUTTERWAVE_SECRET_KEY = os.getenv("FLUTTERWAVE_SECRET_KEY", "")
FLUTTERWAVE_WEBHOOK_HASH = os.getenv("FLUTTERWAVE_WEBHOOK_HASH", "")

# Status codes
STATUS_LOCKED = 200
STATUS_SETTLED = 250
STATUS_FULFILLING = 300


# === Models ===

class PaymentIntentRequest(BaseModel):
    tx_id: str
    amount_zmw: float
    display_currency: str = "USD"  # USD, GBP, EUR
    idempotency_key: str


class PaymentIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str
    display_amount: float
    display_currency: str
    rate_applied: float
    kithly_fee: float


class DisbursementRequest(BaseModel):
    tx_id: str
    shop_id: str
    amount_zmw: float
    mobile_money_number: str
    network: str = "MTN"  # MTN, AIRTEL, ZAMTEL


class DisbursementResponse(BaseModel):
    disbursement_id: str
    status: str
    amount_zmw: float
    mobile_money_number: str


# === Stripe Integration (Sender Side - USD/GBP) ===

@router.post("/stripe/create-intent", response_model=PaymentIntentResponse)
async def create_stripe_intent(request: PaymentIntentRequest):
    """
    Create Stripe PaymentIntent for sender (USD/GBP).
    This locks funds but doesn't confirm - webhook confirms.
    """
    # Import currency oracle
    from services.currency_oracle import CurrencyOracle
    oracle = CurrencyOracle()
    
    # Convert ZMW to display currency with safety buffer
    conversion = await oracle.convert(
        amount=request.amount_zmw,
        from_currency="ZMW",
        to_currency=request.display_currency
    )
    
    # Stripe amount is in cents
    stripe_amount = int(conversion.converted_amount * 100)
    
    # Mock Stripe intent creation (would use stripe.PaymentIntent.create)
    intent_id = f"pi_{request.tx_id[:20]}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    client_secret = f"{intent_id}_secret_{os.urandom(16).hex()}"
    
    # TODO: Real Stripe integration
    # import stripe
    # stripe.api_key = STRIPE_SECRET_KEY
    # intent = stripe.PaymentIntent.create(
    #     amount=stripe_amount,
    #     currency=request.display_currency.lower(),
    #     metadata={"tx_id": request.tx_id},
    #     idempotency_key=request.idempotency_key,
    # )
    
    return PaymentIntentResponse(
        client_secret=client_secret,
        payment_intent_id=intent_id,
        display_amount=conversion.converted_amount,
        display_currency=request.display_currency,
        rate_applied=conversion.rate,
        kithly_fee=conversion.converted_amount * 0.029,  # 2.9% Stripe fee
    )


@router.post("/stripe/webhook")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None),
    db: AsyncSession = Depends(get_db),
):
    """
    Stripe webhook - THE TRUTH for payment confirmation.
    Only this moves status from 100 → 200.
    """
    payload = await request.body()

    # Verify webhook signature
    if STRIPE_WEBHOOK_SECRET:
        try:
            # import stripe
            # event = stripe.Webhook.construct_event(payload, stripe_signature, STRIPE_WEBHOOK_SECRET)
            # For now, mock verification
            event = json.loads(payload)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Webhook verification failed: {e}")
    else:
        event = json.loads(payload)

    event_type = event.get("type")
    data = event.get("data", {}).get("object", {})

    if event_type == "payment_intent.succeeded":
        tx_id = data.get("metadata", {}).get("tx_id")
        if tx_id:
            # Query the database for this transaction
            result = await db.execute(
                select(Transaction).where(Transaction.tx_id == tx_id)
            )
            txn = result.scalar_one_or_none()

            if txn is None:
                logger.warning("[STRIPE] tx_id=%s not found in database", tx_id)
                raise HTTPException(status_code=404, detail=f"Transaction {tx_id} not found")

            # Idempotency: if already confirmed, do nothing
            if txn.status_code >= STATUS_LOCKED:
                logger.info("[STRIPE] tx_id=%s already at status %s — skipping", tx_id, txn.status_code)
                return {"status": "already_processed", "tx_id": tx_id, "current_status": txn.status_code}

            # Update status: 100 → 200 (LOCKED / Confirmed)
            txn.status_code = STATUS_LOCKED
            txn.stripe_payment_ref = data.get("id")  # Stripe PaymentIntent ID
            txn.updated_at = datetime.utcnow()
            await db.commit()

            logger.info("[STRIPE] Payment confirmed for tx_id=%s, status → %s", tx_id, STATUS_LOCKED)
            return {"status": "success", "tx_id": tx_id, "new_status": STATUS_LOCKED}

    elif event_type == "payment_intent.payment_failed":
        tx_id = data.get("metadata", {}).get("tx_id")
        logger.warning("[STRIPE] Payment failed for tx_id=%s", tx_id)
        return {"status": "failed", "tx_id": tx_id}

    return {"status": "received"}


# === Flutterwave Integration (Shop Side - ZMW Mobile Money) ===

@router.post("/flutterwave/disburse", response_model=DisbursementResponse)
async def create_flutterwave_disbursement(request: DisbursementRequest):
    """
    Create Flutterwave disbursement to shop via Mobile Money.
    Only called after delivery is confirmed (status 400+).
    """
    # Generate disbursement ID
    disbursement_id = f"fw_{request.tx_id[:10]}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    
    # TODO: Real Flutterwave integration
    # import requests
    # response = requests.post(
    #     "https://api.flutterwave.com/v3/transfers",
    #     headers={"Authorization": f"Bearer {FLUTTERWAVE_SECRET_KEY}"},
    #     json={
    #         "account_bank": request.network,
    #         "account_number": request.mobile_money_number,
    #         "amount": request.amount_zmw,
    #         "currency": "ZMW",
    #         "reference": disbursement_id,
    #         "debit_currency": "ZMW",
    #         "meta": {"tx_id": request.tx_id, "shop_id": request.shop_id}
    #     }
    # )
    
    return DisbursementResponse(
        disbursement_id=disbursement_id,
        status="PENDING",
        amount_zmw=request.amount_zmw,
        mobile_money_number=request.mobile_money_number,
    )


@router.post("/flutterwave/webhook")
async def flutterwave_webhook(
    request: Request,
    verif_hash: str = Header(None, alias="verif-hash"),
    db: AsyncSession = Depends(get_db),
):
    """
    Flutterwave webhook - THE TRUTH for disbursement confirmation.
    Moves status from 200 → 250 (SETTLED) when shop account is verified.
    """
    payload = await request.json()

    # Verify webhook hash
    if FLUTTERWAVE_WEBHOOK_HASH:
        if verif_hash != FLUTTERWAVE_WEBHOOK_HASH:
            raise HTTPException(status_code=401, detail="Invalid webhook hash")

    event_type = payload.get("event")
    data = payload.get("data", {})

    if event_type == "transfer.completed":
        tx_id = data.get("meta", {}).get("tx_id")
        fw_status = data.get("status")

        if fw_status == "SUCCESSFUL" and tx_id:
            # Query the database for this transaction
            result = await db.execute(
                select(Transaction).where(Transaction.tx_id == tx_id)
            )
            txn = result.scalar_one_or_none()

            if txn is None:
                logger.warning("[FLUTTERWAVE] tx_id=%s not found in database", tx_id)
                return {"status": "not_found", "tx_id": tx_id}

            # Idempotency: if already settled or beyond, skip
            if txn.status_code >= STATUS_SETTLED:
                logger.info("[FLUTTERWAVE] tx_id=%s already at status %s — skipping", tx_id, txn.status_code)
                return {"status": "already_processed", "tx_id": tx_id, "current_status": txn.status_code}

            # Update status: 200 → 250 (SETTLED)
            txn.status_code = STATUS_SETTLED
            txn.is_settled = True
            txn.flutterwave_ref = data.get("reference")
            txn.updated_at = datetime.utcnow()
            await db.commit()

            logger.info("[FLUTTERWAVE] Disbursement settled for tx_id=%s, status → %s", tx_id, STATUS_SETTLED)
            return {"status": "success", "tx_id": tx_id, "new_status": STATUS_SETTLED}

        elif fw_status == "FAILED":
            logger.warning("[FLUTTERWAVE] Disbursement failed for tx_id=%s", tx_id)
            return {"status": "failed", "tx_id": tx_id}

    return {"status": "received"}


# === Account Validation ===

@router.post("/flutterwave/validate-account")
async def validate_shop_account(
    mobile_money_number: str,
    network: str = "MTN"
):
    """
    Pre-validate shop mobile money account before disbursement.
    Called during shop onboarding.
    """
    # TODO: Real Flutterwave account validation
    # response = requests.post(
    #     "https://api.flutterwave.com/v3/accounts/resolve",
    #     headers={"Authorization": f"Bearer {FLUTTERWAVE_SECRET_KEY}"},
    #     json={"account_number": mobile_money_number, "account_bank": network}
    # )
    
    return {
        "valid": True,
        "account_name": f"Shop Account {mobile_money_number[-4:]}",
        "mobile_money_number": mobile_money_number,
        "network": network,
    }
