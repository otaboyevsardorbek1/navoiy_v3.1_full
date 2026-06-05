# app/api/v1/endpoints/asarlar.py
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, update
from sqlalchemy.orm import selectinload
from typing import Optional
from pathlib import Path
import json
from slugify import slugify

from ....db.database import get_db
from ....models.models import User, Asar, AsarPage, Favorite
from ....schemas.schemas import (
    AsarOut, AsarCreate, AsarUpdate,
    PaginatedResponse, AsarContentJSON, PageContent,
)
from ....core.dependencies import get_current_user, get_current_admin
from ....services.content_service import content_service
from ....core.config import settings

router = APIRouter(prefix="/asarlar", tags=["asarlar"])


# ─── List ─────────────────────────────────────────────────────────────────────

@router.get("", response_model=PaginatedResponse)
async def get_asarlar(
    category: Optional[str] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Asar).where(Asar.is_published == True)
    count_query = select(func.count()).select_from(Asar).where(Asar.is_published == True)

    if category:
        query = query.where(Asar.category == category)
        count_query = count_query.where(Asar.category == category)
    if search:
        like = f"%{search}%"
        query = query.where(Asar.title_uz.ilike(like) | Asar.description.ilike(like))
        count_query = count_query.where(Asar.title_uz.ilike(like) | Asar.description.ilike(like))

    total = (await db.execute(count_query)).scalar_one()
    offset = (page - 1) * limit
    result = await db.execute(
        query.options(selectinload(Asar.pages))
             .order_by(Asar.id)
             .offset(offset)
             .limit(limit)
    )
    asarlar = result.scalars().all()

    return PaginatedResponse(
        items=[AsarOut.model_validate(a) for a in asarlar],
        total=total,
        page=page,
        limit=limit,
        pages=(total + limit - 1) // limit,
    )


# ─── Detail ───────────────────────────────────────────────────────────────────

@router.get("/{slug}", response_model=AsarOut)
async def get_asar(
    slug: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Asar)
        .where(Asar.slug == slug, Asar.is_published == True)
        .options(selectinload(Asar.pages))
    )
    asar = result.scalar_one_or_none()
    if not asar:
        raise HTTPException(status_code=404, detail="Asar topilmadi")

    # Read count oshirish
    await db.execute(update(Asar).where(Asar.id == asar.id).values(read_count=Asar.read_count + 1))
    await db.commit()
    return AsarOut.model_validate(asar)


# ─── Download full content JSON ───────────────────────────────────────────────

@router.get("/{slug}/content", summary="To'liq mazmunni JSON yuklab olish")
async def download_asar_content(
    slug: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Flutter offline sync uchun — to'liq JSON faylni qaytaradi."""
    result = await db.execute(select(Asar).where(Asar.slug == slug, Asar.is_published == True))
    asar = result.scalar_one_or_none()
    if not asar:
        raise HTTPException(status_code=404, detail="Asar topilmadi")

    content = await content_service.read_asar_content(slug)
    if not content:
        raise HTTPException(status_code=404, detail="Kontent fayli mavjud emas")

    return content


@router.get("/{slug}/page/{page_number}", summary="Bitta sahifani olish")
async def get_asar_page(
    slug: str,
    page_number: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    page = await content_service.read_asar_page(slug, page_number)
    if not page:
        raise HTTPException(status_code=404, detail="Sahifa topilmadi")
    return page


# ─── Upload content (Admin) ───────────────────────────────────────────────────

@router.post("/{slug}/content", summary="Kontent yuklash (Admin)")
async def upload_asar_content(
    slug: str,
    content: AsarContentJSON,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(Asar).where(Asar.slug == slug))
    asar = result.scalar_one_or_none()
    if not asar:
        raise HTTPException(status_code=404, detail="Asar topilmadi")

    checksum, file_size = await content_service.save_asar_content(slug, content)

    # DB ni yangilash
    await db.execute(
        update(Asar).where(Asar.id == asar.id).values(
            content_file=f"content/asarlar/{slug}.json",
            total_pages=content.total_pages,
            checksum=checksum,
            version=Asar.version + 1,
        )
    )

    # Pages meta ni yangilash
    for page_data in content.pages:
        page_result = await db.execute(
            select(AsarPage).where(
                AsarPage.asar_id == asar.id,
                AsarPage.page_number == page_data.page_number,
            )
        )
        page = page_result.scalar_one_or_none()
        if page:
            page.title = page_data.title
            page.word_count = page_data.word_count
            page.has_quiz = len(page_data.quizzes) > 0
        else:
            db.add(AsarPage(
                asar_id=asar.id,
                page_number=page_data.page_number,
                title=page_data.title,
                word_count=page_data.word_count,
                has_quiz=len(page_data.quizzes) > 0,
            ))

    await db.commit()
    return {"detail": "Kontent saqlandi", "checksum": checksum, "file_size": file_size}


# ─── CRUD (Admin) ─────────────────────────────────────────────────────────────

@router.post("", response_model=AsarOut, status_code=201)
async def create_asar(
    body: AsarCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    slug = slugify(body.title_uz, allow_unicode=True)
    existing = await db.execute(select(Asar).where(Asar.slug == slug))
    if existing.scalar_one_or_none():
        slug = f"{slug}-{body.year or 'new'}"

    asar = Asar(
        title=body.title,
        title_uz=body.title_uz,
        slug=slug,
        description=body.description,
        category=body.category,
        image_url=body.image_url,
        year=body.year,
        language=body.language,
        tags=body.tags,
    )
    db.add(asar)
    await db.commit()
    await db.refresh(asar)

    # Demo kontent yaratish
    sample = content_service.create_sample_asar_content(asar.id, slug, body.title_uz)
    checksum, file_size = await content_service.save_asar_content(slug, sample)
    asar.content_file = f"content/asarlar/{slug}.json"
    asar.total_pages = sample.total_pages
    asar.checksum = checksum
    db.add(AsarPage(asar_id=asar.id, page_number=1, title="Kirish", has_quiz=True))
    db.add(AsarPage(asar_id=asar.id, page_number=2, title="Asosiy qism", has_quiz=False))
    await db.commit()

    result = await db.execute(
        select(Asar).where(Asar.id == asar.id).options(selectinload(Asar.pages))
    )
    return AsarOut.model_validate(result.scalar_one())


@router.patch("/{slug}", response_model=AsarOut)
async def update_asar(
    slug: str,
    body: AsarUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(Asar).where(Asar.slug == slug))
    asar = result.scalar_one_or_none()
    if not asar:
        raise HTTPException(status_code=404, detail="Topilmadi")

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(asar, field, value)
    await db.commit()
    await db.refresh(asar)
    return AsarOut.model_validate(asar)


@router.delete("/{slug}", status_code=204)
async def delete_asar(
    slug: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(Asar).where(Asar.slug == slug))
    asar = result.scalar_one_or_none()
    if not asar:
        raise HTTPException(status_code=404, detail="Topilmadi")
    await content_service.delete_asar_content(slug)
    await db.delete(asar)
    await db.commit()
