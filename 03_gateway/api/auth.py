"""
=============================================================================
KithLy Global Protocol - LAYER 3: THE TRANSLATOR (Python/FastAPI)
auth.py - Authentication Endpoints
=============================================================================
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from typing import Optional
import jwt
import os

router = APIRouter(prefix="/auth", tags=["Authentication"])

# Configuration
SECRET_KEY = os.getenv("KITHLY_JWT_SECRET", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")


# === Pydantic Models ===

class UserCreate(BaseModel):
    phone: str
    email: Optional[EmailStr] = None
    name: str
    role: str = "customer"  # customer, rider, shop_admin


class UserResponse(BaseModel):
    id: str
    phone: str
    email: Optional[str]
    name: str
    role: str
    created_at: datetime


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse


class TokenData(BaseModel):
    user_id: str
    role: str
    exp: datetime


# === Token Utilities ===

def create_access_token(user_id: str, role: str) -> tuple[str, datetime]:
    """Generate JWT access token."""
    expires = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {
        "sub": user_id,
        "role": role,
        "exp": expires,
        "iat": datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token, expires


def verify_token(token: str) -> TokenData:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return TokenData(
            user_id=payload["sub"],
            role=payload["role"],
            exp=datetime.fromtimestamp(payload["exp"])
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )


async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenData:
    """Dependency to get current authenticated user."""
    return verify_token(token)


def require_role(*allowed_roles: str):
    """Dependency factory to require specific roles."""
    async def role_checker(current_user: TokenData = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{current_user.role}' not authorized for this action"
            )
        return current_user
    return role_checker


# === Endpoints ===

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate):
    """Register a new user."""
    # TODO: Implement actual user creation with database
    # For now, return mock response
    return UserResponse(
        id="usr_mock_" + user.phone[-4:],
        phone=user.phone,
        email=user.email,
        name=user.name,
        role=user.role,
        created_at=datetime.utcnow()
    )


@router.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login and receive access token."""
    # TODO: Implement actual authentication with database
    # form_data.username is the phone number
    # form_data.password is the OTP or password
    
    # Mock authentication
    user_id = "usr_mock_" + form_data.username[-4:]
    role = "customer"
    
    token, expires = create_access_token(user_id, role)
    
    return Token(
        access_token=token,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse(
            id=user_id,
            phone=form_data.username,
            email=None,
            name="Mock User",
            role=role,
            created_at=datetime.utcnow()
        )
    )


@router.post("/otp/request")
async def request_otp(phone: str):
    """Request OTP for phone verification."""
    # TODO: Integrate with SMS provider
    return {"message": "OTP sent", "phone": phone}


@router.post("/otp/verify")
async def verify_otp(phone: str, otp: str):
    """Verify OTP code."""
    # TODO: Implement OTP verification
    return {"verified": True, "phone": phone}


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: TokenData = Depends(get_current_user)):
    """Get current user profile."""
    # TODO: Fetch from database
    return UserResponse(
        id=current_user.user_id,
        phone="+260XXXXXXXXX",
        email=None,
        name="Current User",
        role=current_user.role,
        created_at=datetime.utcnow()
    )


@router.post("/refresh", response_model=Token)
async def refresh_token(current_user: TokenData = Depends(get_current_user)):
    """Refresh access token."""
    token, expires = create_access_token(current_user.user_id, current_user.role)
    
    return Token(
        access_token=token,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse(
            id=current_user.user_id,
            phone="+260XXXXXXXXX",
            email=None,
            name="Current User",
            role=current_user.role,
            created_at=datetime.utcnow()
        )
    )
