# app/api/v1/endpoints/sync.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from datetime import datetime, timezone
from typing import Optional, List 

from ....db.database import get_db
from ....models.models import User, Asar, Sher, SyncManifest, ReadProgress
from ....schemas.schemas import (
    SyncManifestResponse, SyncItemMeta,
    SyncCheckRequest, SyncCheckResponse,
    ReadProgressUpdate, ReadProgressOut,
)
from ....core.dependencies import get_current_user
from ....services.content_service import content_service
from ....core.config import settings

router = APIRouter(prefix="/sync", tags=["sync"])


# ─── Full manifest ────────────────────────────────────────────────────────────

@router.get("/manifest", response_model=SyncManifestResponse)
async def get_sync_manifest(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Client bu endpoint orqali barcha kontentning ro'yxatini oladi.
    Keyin o'zida yo'q yoki eskirgan fayllarni /sync/download/* dan yuklab oladi.
    """
    asar_result = await db.execute(
        select(Asar).where(Asar.is_published == True, Asar.checksum != None)
    )
    asarlar = asar_result.scalars().all()

    sher_result = await db.execute(
        select(Sher).where(Sher.is_published == True)
    )
    sherlar = sher_result.scalars().all()

    asar_items = []
    for a in asarlar:
        file_size = await content_service.get_asar_file_size(a.slug)
        asar_items.append(SyncItemMeta(
            id=a.id,
            slug=a.slug,
            content_type="asar",
            version=a.version,
            checksum=a.checksum or "",
            file_size_bytes=file_size,
            updated_at=a.updated_at or datetime.now(timezone.utc),
        ))

    sher_items = []
    for s in sherlar:
        sher_items.append(SyncItemMeta(
            id=s.id,
            slug=s.slug,
            content_type="sher",
            version=s.version,
            checksum="",
            file_size_bytes=len(s.content.encode()),
            updated_at=s.updated_at or datetime.now(timezone.utc),
        ))

    return SyncManifestResponse(
        bundle_version=settings.SYNC_BUNDLE_VERSION,
        generated_at=datetime.now(timezone.utc),
        asarlar=asar_items,
        sherlar=sher_items,
        total_items=len(asar_items) + len(sher_items),
    )


# ─── Delta check ──────────────────────────────────────────────────────────────

@router.post("/check", response_model=SyncCheckResponse)
async def check_sync_status(
    body: SyncCheckRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Client o'zidagi versiyalarni yuboradi.
    Server nimani yangilash kerakligini aytadi.
    """
    needs_update = []
    up_to_date = []

    for slug, local_version in body.local_versions.items():
        result = await db.execute(select(Asar).where(Asar.slug == slug, Asar.is_published == True))
        asar = result.scalar_one_or_none()
        if not asar:
            continue
        if asar.version > local_version:
            file_size = await content_service.get_asar_file_size(slug)
            needs_update.append(SyncItemMeta(
                id=asar.id,
                slug=slug,
                content_type="asar",
                version=asar.version,
                checksum=asar.checksum or "",
                file_size_bytes=file_size,
                updated_at=asar.updated_at or datetime.now(timezone.utc),
            ))
        else:
            up_to_date.append(slug)

    return SyncCheckResponse(needs_update=needs_update, up_to_date=up_to_date)


# ─── Download content bundle ──────────────────────────────────────────────────

@router.get("/download/asar/{slug}")
async def download_asar_bundle(
    slug: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Offline uchun to'liq asar JSON yuklab olish."""
    result = await db.execute(select(Asar).where(Asar.slug == slug, Asar.is_published == True))
    asar = result.scalar_one_or_none()
    if not asar:
        raise HTTPException(status_code=404, detail="Asar topilmadi")

    content = await content_service.read_asar_content(slug)
    if not content:
        raise HTTPException(status_code=404, detail="Kontent mavjud emas")

    return JSONResponse(
        content=content,
        headers={
            "X-Content-Version": str(asar.version),
            "X-Content-Checksum": asar.checksum or "",
            "X-Content-Slug": slug,
            "Cache-Control": "public, max-age=3600",
        },
    )


@router.get("/download/sherlar")
async def download_all_sherlar(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Barcha she'rlarni bitta JSON da yuklab olish."""
    result = await db.execute(select(Sher).where(Sher.is_published == True))
    sherlar = result.scalars().all()

    data = [
        {
            "id": s.id,
            "title": s.title,
            "slug": s.slug,
            "content": s.content,
            "type": s.type.value,
            "description": s.description,
            "asar_id": s.asar_id,
            "audio_url": s.audio_url,
            "like_count": s.like_count,
            "version": s.version,
            "updated_at": s.updated_at.isoformat() if s.updated_at else None,
        }
        for s in sherlar
    ]

    return JSONResponse(
        content={
            "version": settings.SYNC_BUNDLE_VERSION,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "total": len(data),
            "sherlar": data,
        },
        headers={
            "Cache-Control": "public, max-age=1800",
        },
    )


# ─── Read Progress sync ───────────────────────────────────────────────────────

@router.post("/progress", response_model=ReadProgressOut)
async def sync_read_progress(
    body: ReadProgressUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Client sahifani o'zgartirganda serverga yuboradi."""
    result = await db.execute(
        select(ReadProgress).where(
            ReadProgress.user_id == current_user.id,
            ReadProgress.asar_id == body.asar_id,
        )
    )
    progress = result.scalar_one_or_none()

    if progress:
        progress.current_page = body.current_page
        progress.scroll_offset = body.scroll_offset
        progress.is_completed = body.is_completed
    else:
        # asar total_pages ni olish
        asar_result = await db.execute(select(Asar).where(Asar.id == body.asar_id))
        asar = asar_result.scalar_one_or_none()
        progress = ReadProgress(
            user_id=current_user.id,
            asar_id=body.asar_id,
            current_page=body.current_page,
            total_pages=asar.total_pages if asar else 1,
            scroll_offset=body.scroll_offset,
            is_completed=body.is_completed,
        )
        db.add(progress)

    await db.commit()
    await db.refresh(progress)
    return ReadProgressOut.model_validate(progress)


@router.get("/progress", response_model=List[ReadProgressOut])  # <-- list o'rniga List
async def get_all_progress(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Login bo'lganda barcha progressni yuklab olish."""
    result = await db.execute(
        select(ReadProgress).where(ReadProgress.user_id == current_user.id)
    )
    return [ReadProgressOut.model_validate(p) for p in result.scalars().all()]

@router.get("/progress/{asar_id}", response_model=ReadProgressOut)
async def get_progress(
    asar_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(ReadProgress).where(
            ReadProgress.user_id == current_user.id,
            ReadProgress.asar_id == asar_id,
        )
    )
    progress = result.scalar_one_or_none()
    if not progress:
        raise HTTPException(status_code=404, detail="Progress topilmadi")
    return ReadProgressOut.model_validate(progress)
