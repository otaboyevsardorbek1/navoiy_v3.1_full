from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..models.models import User, QuizResult

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])

@router.get("")
async def get_leaderboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Har bir foydalanuvchi uchun umumiy ballarni hisoblash
    stmt = select(
        User.id,
        User.username,
        User.full_name,
        func.coalesce(func.sum(QuizResult.points_earned), 0).label("total_points")
    ).outerjoin(QuizResult).group_by(User.id).order_by(func.sum(QuizResult.points_earned).desc())
    
    result = await db.execute(stmt)
    rows = result.all()
    
    rankings = []
    for rank, row in enumerate(rows, start=1):
        rankings.append({
            "user_id": row.id,
            "username": row.username,
            "full_name": row.full_name or row.username,
            "total_points": row.total_points,
            "rank": rank
        })
    
    return {"rankings": rankings}