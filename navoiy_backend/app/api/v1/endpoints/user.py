from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..models.models import User, ReadProgress, QuizResult, Favorite
from ..core.dependencies import get_current_user

router = APIRouter(prefix="/user", tags=["user"])

@router.get("/stats")
async def get_user_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # O‘qilgan asarlar soni (hech bo‘lmaganda bir sahifasini ochgan)
    read_count_query = select(func.count()).select_from(ReadProgress).where(ReadProgress.user_id == current_user.id)
    total_read = (await db.execute(read_count_query)).scalar() or 0
    
    # Tugatilgan asarlar soni (is_completed = True)
    completed_query = select(func.count()).select_from(ReadProgress).where(ReadProgress.user_id == current_user.id, ReadProgress.is_completed == True)
    completed = (await db.execute(completed_query)).scalar() or 0
    
    # Davom etayotganlar
    in_progress = total_read - completed
    
    # Jami quiz javoblari
    quiz_count_query = select(func.count()).select_from(QuizResult).where(QuizResult.user_id == current_user.id)
    total_quiz_answered = (await db.execute(quiz_count_query)).scalar() or 0
    
    # To‘g‘ri javoblar soni
    correct_query = select(func.count()).select_from(QuizResult).where(QuizResult.user_id == current_user.id, QuizResult.is_correct == True)
    correct_answers = (await db.execute(correct_query)).scalar() or 0
    
    # Jami ballar
    points_query = select(func.coalesce(func.sum(QuizResult.points_earned), 0)).select_from(QuizResult).where(QuizResult.user_id == current_user.id)
    total_points = (await db.execute(points_query)).scalar() or 0
    
    # Sevimlilar soni
    fav_query = select(func.count()).select_from(Favorite).where(Favorite.user_id == current_user.id)
    favorite_count = (await db.execute(fav_query)).scalar() or 0
    
    return {
        "total_read": total_read,
        "completed": completed,
        "in_progress": in_progress,
        "total_quiz_answered": total_quiz_answered,
        "correct_answers": correct_answers,
        "total_points": total_points,
        "favorite_count": favorite_count,
    }