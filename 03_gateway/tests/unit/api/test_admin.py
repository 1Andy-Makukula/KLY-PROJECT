"""
=============================================================================
KithLy Global Protocol - ADMIN API TESTS (Phase VI)
test_admin.py - Verify admin endpoints return expected responses
=============================================================================
"""


def test_get_pending_shops_returns_200(client):
    """
    GET /api/admin/shops/pending should return HTTP 200
    with a list of pending shop applications.
    """
    response = client.get("/api/admin/shops/pending")

    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1

    # Verify the mock data structure has expected fields
    shop = data[0]
    assert "shop_id" in shop
    assert "name" in shop
    assert "owner_name" in shop
    assert "city" in shop
    assert "created_at" in shop


def test_pending_shops_contain_lusaka_mock_data(client):
    """
    The current mock implementation should return Lusaka-based shops.
    This validates the mock data contract before real DB integration.
    """
    response = client.get("/api/admin/shops/pending")
    data = response.json()

    cities = [shop["city"] for shop in data]
    assert "Lusaka" in cities
