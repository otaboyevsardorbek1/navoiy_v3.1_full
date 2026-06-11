# app/api/v1/endpoints/auth.py
from fastapi import APIRouter, Depends, HTTPException, status, Request, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from datetime import datetime, timezone, timedelta
from jose import JWTError
import hashlib
from pydantic import BaseModel

from ....db.database import get_db
from ....models.models import User, RefreshToken
from ....schemas.schemas import LoginRequest, TokenResponse, RefreshRequest, UserCreate, UserOut
from ....core.security import (
    verify_password, hash_password,
    create_access_token, create_refresh_token,
    decode_token, verify_token_type,
)
from ....core.config import settings
from ....core.dependencies import get_current_user

# Email va Redis uchun yangi importlar
from app.services.email_service import send_email
from app.core.redis_client import get_redis
from app.core.security import generate_random_token

router = APIRouter(prefix="/auth", tags=["auth"])


def _hash_refresh(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


# ========================= LOGIN =========================
@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.username == body.username))
    user: User | None = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login yoki parol noto'g'ri",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hisob bloklangan",
        )
    if not user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email manzilingiz tasdiqlanmagan. Pochtangizni tekshiring.",
        )

    # Tokens
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    # Save refresh token
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    db.add(RefreshToken(
        user_id=user.id,
        token_hash=_hash_refresh(refresh_token),
        expires_at=expire,
        device_info=body.device_info or request.headers.get("user-agent", "")[:255],
    ))

    # Update last_login
    await db.execute(
        update(User).where(User.id == user.id).values(last_login=datetime.now(timezone.utc))
    )
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserOut.model_validate(user),
    )


# ========================= REFRESH TOKEN =========================
@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Refresh token yaroqsiz",
    )
    try:
        payload = decode_token(body.refresh_token)
        if not verify_token_type(payload, "refresh"):
            raise credentials_exc
        user_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise credentials_exc

    token_hash = _hash_refresh(body.refresh_token)
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.is_revoked == False,
            RefreshToken.expires_at > datetime.now(timezone.utc),
        )
    )
    stored = result.scalar_one_or_none()
    if not stored:
        raise credentials_exc

    # Revoke old, issue new
    stored.is_revoked = True

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if not user or not user.is_active:
        raise credentials_exc

    new_access = create_access_token(user.id)
    new_refresh = create_refresh_token(user.id)
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    db.add(RefreshToken(
        user_id=user.id,
        token_hash=_hash_refresh(new_refresh),
        expires_at=expire,
    ))
    await db.commit()

    return TokenResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserOut.model_validate(user),
    )


# ========================= LOGOUT =========================
@router.post("/logout")
async def logout(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    token_hash = _hash_refresh(body.refresh_token)
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.user_id == current_user.id,
        )
    )
    stored = result.scalar_one_or_none()
    if stored:
        stored.is_revoked = True
        await db.commit()
    return {"detail": "Tizimdan chiqdingiz"}


# ========================= REGISTER (with email verification) =========================
@router.post("/register", response_model=UserOut)
async def register(
    body: UserCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    # Check duplicate
    existing = await db.execute(select(User).where(User.username == body.username))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Bu username band")

    user = User(
        username=body.username,
        email=body.email,
        full_name=body.full_name,
        hashed_password=hash_password(body.password),
        role=body.role,
        email_verified=False,          # default
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    # Generate verification token (Redis da saqlaymiz, 24 soat)
    token = generate_random_token()
    redis = await get_redis()
    await redis.setex(f"verify_token:{token}", 86400, str(user.id))  # 24 soat

    verify_link = f"{settings.FRONTEND_URL}/#verify-email?token={token}"
    html = f"""
    <h2>Xush kelibsiz, {user.full_name or user.username}!</h2>
    <p>Iltimos, email manzilingizni tasdiqlash uchun <a href='{verify_link}'>ushbu havolani bosing</a>.</p>
    <p>Havola 24 soat amal qiladi.</p>
    """
    background_tasks.add_task(send_email, user.email, "Emailni tasdiqlang", html)

    return UserOut.model_validate(user)


# ========================= EMAIL VERIFICATION =========================
@router.get("/verify-email")
async def verify_email(
    token: str,
    db: AsyncSession = Depends(get_db),
):
    redis = await get_redis()
    user_id = await redis.get(f"verify_token:{token}")
    if not user_id:
        raise HTTPException(400, "Noto‘g‘ri yoki eskirgan token")

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(400, "Foydalanuvchi topilmadi")

    user.email_verified = True
    await db.commit()
    await redis.delete(f"verify_token:{token}")
    return {"detail": "Email muvaffaqiyatli tasdiqlandi"}


# ========================= FORGOT PASSWORD (send reset link) =========================
@router.post("/forgot-password")
async def forgot_password(
    email: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    # Xavfsizlik uchun foydalanuvchi topilmasa ham "OK" javob qaytaramiz
    if not user:
        return {"detail": "Agar email mavjud bo‘lsa, tiklash havolasi yuborildi"}

    token = generate_random_token()
    redis = await get_redis()
    await redis.setex(f"reset_token:{token}", 3600, str(user.id))  # 1 soat

    reset_link = f"{settings.FRONTEND_URL}/#reset-password?token={token}"
    html = f"""
    <h2>Parolni tiklash</h2>
    <p>Parolingizni tiklash uchun <a href='{reset_link}'>ushbu havolani bosing</a>.</p>
    <p>Havola 1 soat amal qiladi.</p>
    """
    background_tasks.add_task(send_email, user.email, "Parolni tiklash", html)
    return {"detail": "Parolni tiklash havolasi emailga yuborildi"}


class ResetPasswordConfirm(BaseModel):
    token: str
    new_password: str


# ========================= RESET PASSWORD (confirm) =========================
@router.post("/reset-password")
async def reset_password_confirm(
    body: ResetPasswordConfirm,
    db: AsyncSession = Depends(get_db),
):
    redis = await get_redis()
    user_id = await redis.get(f"reset_token:{body.token}")
    if not user_id:
        raise HTTPException(400, "Noto‘g‘ri yoki eskirgan token")

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(400, "Foydalanuvchi topilmadi")

    user.hashed_password = hash_password(body.new_password)
    await db.commit()
    await redis.delete(f"reset_token:{body.token}")
    return {"detail": "Parol muvaffaqiyatli o‘zgartirildi"}


# ========================= GET CURRENT USER =========================
@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)