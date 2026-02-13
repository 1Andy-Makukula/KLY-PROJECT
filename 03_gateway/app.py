"""
=============================================================================
KithLy Global Protocol - GATEWAY APPLICATION (Phase VI)
app.py - FastAPI Application Entry Point
=============================================================================

Mounts all API routers under the /api prefix.
Used by both uvicorn (production) and TestClient (testing).
"""

from fastapi import FastAPI
from api.admin import router as admin_router

app = FastAPI(
    title="KithLy Global Protocol - Gateway",
    description="Gift delivery orchestration API",
    version="0.6.0",
)

# Mount routers
app.include_router(admin_router, prefix="/api")
