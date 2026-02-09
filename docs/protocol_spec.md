# KithLy Global Protocol Specification

## Overview

The KithLy Global Protocol is a 5-layer architecture for gift delivery orchestration, using a 100-900 status code system to track gift journeys from creation to gratitude.

## Status Codes (The Protocol)

| Code | Status | Description |
|------|--------|-------------|
| 100 | INITIATED | Gift created, awaiting payment |
| 200 | PAID | Payment confirmed, ready for assignment |
| 310 | ASSIGNED | Rider assigned to pickup |
| 320 | PICKUP_EN_ROUTE | Rider heading to shop |
| 330 | PICKED_UP | Gift collected from shop |
| 340 | DELIVERY_EN_ROUTE | Rider heading to receiver |
| 400 | DELIVERED | Gift handed over |
| 500 | CONFIRMED | Receiver confirmed receipt |
| 600 | GRATITUDE_SENT | Thank-you message recorded |
| 700 | COMPLETED | Full cycle complete |
| 800 | DISPUTED | Issue raised |
| 900 | RESOLVED | Dispute settled / Refunded |

## Architecture Layers

### Layer 1: Bedrock (SQL)
PostgreSQL with PostGIS for geospatial queries. Stores the immutable truth.

### Layer 2: Core Logic (C++23)
High-performance state machine, proximity algorithms, and idempotency guards.

### Layer 3: Gateway (Python/FastAPI)
REST API, AI agent protocols (UCP/AP2), Gemini Vision integration.

### Layer 4: Skin (Flutter)
Cross-platform mobile app with status-driven UI updates.

### Layer 5: Ops (Docker/K8s)
Containerized deployment with docker-compose and Kubernetes support.

## AI Protocols

- **UCP** (Universal Connection Protocol): Agent discovery and handshake
- **AP2** (Agent Payment Protocol v2): Autonomous payment mandates
