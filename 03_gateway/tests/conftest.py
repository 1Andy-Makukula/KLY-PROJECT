"""
=============================================================================
KithLy Global Protocol - TEST FIXTURES (Phase VI)
conftest.py - Shared pytest fixtures
=============================================================================
"""

import os
os.environ["TESTING"] = "True"

import pytest
from fastapi.testclient import TestClient
from app import app


@pytest.fixture
def client():
    """FastAPI TestClient for integration-style tests."""
    return TestClient(app)


@pytest.fixture
def mock_db():
    """
    In-memory dictionary acting as a mock database.
    Provides empty collections for each domain entity.
    """
    return {
        "shops": [],
        "orders": [],
        "riders": [],
        "gifts": [],
        "users": [],
    }


@pytest.fixture
def gift_data():
    """
    Sample gift order JSON matching the Gateway's expected schema.
    Represents a Status 100 (INITIATED) gift.
    """
    return {
        "tx_id": "test-tx-001",
        "tx_ref": "KLY-TEST-2026-001",
        "receiver_phone": "+260977111222",
        "receiver_name": "Test Receiver",
        "shop_id": "shop-test-001",
        "product_id": "prod-test-001",
        "product_name": "Birthday Cake - Vanilla",
        "quantity": 1,
        "unit_price": 250.00,
        "total_amount": 250.00,
        "currency": "ZMW",
        "status": 100,
        "message": "Happy Birthday!",
    }
