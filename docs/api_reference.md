# KithLy API Reference

## Base URL
```
http://localhost:8000
```

## Authentication

### Register
```http
POST /auth/register
Content-Type: application/json

{
  "phone": "+260971234567",
  "name": "John Doe",
  "email": "john@example.com"
}
```

### Login
```http
POST /auth/token
Content-Type: application/x-www-form-urlencoded

username=+260971234567&password=123456
```

## Gifts

### Create Gift
```http
POST /gifts/
Authorization: Bearer <token>
Content-Type: application/json

{
  "receiver_phone": "+260979876543",
  "receiver_name": "Jane Doe",
  "shop_id": "shop_123",
  "product_id": "prod_456",
  "quantity": 1,
  "message": "Happy Birthday!"
}
```

### Get Gift Status
```http
GET /gifts/{tx_id}
Authorization: Bearer <token>
```

### List My Gifts
```http
GET /gifts/?role=sender&limit=20
Authorization: Bearer <token>
```

## AI Agents

### Agent Manifest
```http
GET /agents/manifest
```

### Initiate Handshake
```http
POST /agents/handshake
Content-Type: application/json

{
  "agent_id": "external-agent-123",
  "agent_name": "My AI Agent",
  "agent_version": "1.0.0",
  "requested_capabilities": ["gift.create", "gift.status"],
  "callback_url": "https://myagent.example/webhook"
}
```

## Payments (AP2)

### Create Payment Mandate
```http
POST /payments/ap2/mandates
X-User-Id: user_123
Content-Type: application/json

{
  "agent_id": "agent_456",
  "mandate_type": "one_time",
  "max_amount_per_tx": 100.00,
  "currency": "ZMW"
}
```

### Execute Payment
```http
POST /payments/ap2/execute
X-Agent-Id: agent_456
Content-Type: application/json

{
  "mandate_id": "mdt_xxx",
  "amount": 50.00,
  "recipient_id": "shop_789",
  "purpose": "Gift payment"
}
```
