# app/api/v1/endpoints/sherlar.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional
from slugify import slugify

from ....db.database import get_db
from ....models.models import User, Sher, Favorite
from ....schemas.schemas import SherOut, SherCreate, PaginatedResponse
from ....core.dependencies import get_current_user, get_current_admin

router = APIRouter(prefix="/sherlar", tags=["sherlar"])


@router.get("", response_model=PaginatedResponse)
async def get_sherlar(
    sher_type: Optional[str] = Query(None, alias="type"),
    search: Optional[str] = None,
    asar_id: Optional[int] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Sher).where(Sher.is_published == True)
    count_q = select(func.count()).select_from(Sher).where(Sher.is_published == True)

    if sher_type:
        query = query.where(Sher.type == sher_type)
        count_q = count_q.where(Sher.type == sher_type)
    if asar_id:
        query = query.where(Sher.asar_id == asar_id)
        count_q = count_q.where(Sher.asar_id == asar_id)
    if search:
        like = f"%{search}%"
        query = query.where(Sher.title.ilike(like) | Sher.content.ilike(like))
        count_q = count_q.where(Sher.title.ilike(like) | Sher.content.ilike(like))

    total = (await db.execute(count_q)).scalar_one()
    offset = (page - 1) * limit
    result = await db.execute(query.order_by(Sher.id).offset(offset).limit(limit))
    sherlar = result.scalars().all()

    return PaginatedResponse(
        items=[SherOut.model_validate(s) for s in sherlar],
        total=total, page=page, limit=limit,
        pages=(total + limit - 1) // limit,
    )


@router.get("/{slug}", response_model=SherOut)
async def get_sher(
    slug: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Sher).where(Sher.slug == slug, Sher.is_published == True))
    sher = result.scalar_one_or_none()
    if not sher:
        raise HTTPException(status_code=404, detail="She'r topilmadi")
    return SherOut.model_validate(sher)


@router.post("", response_model=SherOut, status_code=201)
async def create_sher(
    body: SherCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    slug = slugify(body.title, allow_unicode=True)
    sher = Sher(
        title=body.title, slug=slug,
        content=body.content, type=body.type,
        description=body.description, asar_id=body.asar_id,
        audio_url=body.audio_url,
    )
    db.add(sher)
    await db.commit()
    await db.refresh(sher)
    return SherOut.model_validate(sher)


# ─── Favorites ────────────────────────────────────────────────────────────────

@router.post("/{sher_id}/favorite")
async def toggle_sher_favorite(
    sher_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.sher_id == sher_id,
        )
    )
    fav = result.scalar_one_or_none()
    if fav:
        await db.delete(fav)
        await db.commit()
        return {"is_favorite": False}
    else:
        db.add(Favorite(user_id=current_user.id, sher_id=sher_id))
        await db.commit()
        return {"is_favorite": True}


# ─── Quiz endpoints ───────────────────────────────────────────────────────────

from ....models.models import Quiz, QuizResult, AsarPage
from ....schemas.schemas import QuizOut, QuizCreate, QuizSubmit, QuizSubmitResult

quiz_router = APIRouter(prefix="/quiz", tags=["quiz"])


@quiz_router.post("/submit", response_model=QuizSubmitResult)
async def submit_quiz(
    body: QuizSubmit,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Quiz).where(Quiz.id == body.quiz_id))
    quiz = result.scalar_one_or_none()
    if not quiz:
        raise HTTPException(status_code=404, detail="Savol topilmadi")

    is_correct = sorted(body.selected_answers) == sorted(quiz.correct_answers)
    points = quiz.points if is_correct else 0

    db.add(QuizResult(
        user_id=current_user.id,
        quiz_id=quiz.id,
        selected_answers=body.selected_answers,
        is_correct=is_correct,
        points_earned=points,
        time_spent_seconds=body.time_spent_seconds,
    ))
    await db.commit()

    return QuizSubmitResult(
        quiz_id=quiz.id,
        is_correct=is_correct,
        points_earned=points,
        correct_answers=quiz.correct_answers,
        explanation=quiz.explanation,
    )


@quiz_router.post("", response_model=QuizOut, status_code=201)
async def create_quiz(
    body: QuizCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    quiz = Quiz(**body.model_dump())
    db.add(quiz)
    await db.commit()
    await db.refresh(quiz)

    # Update page has_quiz flag
    await db.execute(
        select(AsarPage).where(AsarPage.id == body.page_id)
    )
    page_result = await db.execute(select(AsarPage).where(AsarPage.id == body.page_id))
    page = page_result.scalar_one_or_none()
    if page:
        page.has_quiz = True
        await db.commit()

    return QuizOut.model_validate(quiz)
