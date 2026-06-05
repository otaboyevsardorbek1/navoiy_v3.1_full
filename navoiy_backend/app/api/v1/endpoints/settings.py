# app/api/v1/endpoints/settings.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Dict

from ....db.database import get_db
from ....models.models import User, AppSetting
from ....core.dependencies import get_current_admin

router = APIRouter(prefix="/admin/settings", tags=["admin-settings"])

@router.get("")
async def get_settings(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
) -> Dict[str, str]:
    """Barcha tizim sozlamalarini (masalan, bot_token, chat_id) qaytaradi."""
    result = await db.execute(select(AppSetting))
    settings = result.scalars().all()
    return {s.key: s.value for s in settings}

@router.post("")
async def update_setting(
    key: str = Query(..., description="Sozlama kaliti (masalan: bot_token)"),
    value: str = Query(..., description="Sozlama qiymati"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Tizim sozlamasini yangilaydi yoki yangisini yaratadi."""
    result = await db.execute(select(AppSetting).where(AppSetting.key == key))
    setting = result.scalar_one_or_none()
    
    if setting:
        setting.value = value
    else:
        db.add(AppSetting(key=key, value=value))
    
    await db.commit()
    return {"status": "success", "key": key}