# app/schemas/schemas.py
from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional, List, Any, Dict 
from datetime import datetime
from ..models.models import UserRole, AsarCategory, SherType, QuizType

# ─── Common ───────────────────────────────────────────────────────────────────

class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    limit: int
    pages: int


# ─── Auth ─────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str
    device_info: Optional[str] = None
    remember_me: bool = False


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: "UserOut"


class RefreshRequest(BaseModel):
    refresh_token: str


# ─── User ─────────────────────────────────────────────────────────────────────

class UserOut(BaseModel):
    id: int
    username: str
    email: Optional[str]
    full_name: Optional[str]
    role: UserRole
    is_active: bool
    avatar_url: Optional[str]
    last_login: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class UserCreate(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: str
    role: UserRole = UserRole.user

    @field_validator("username")
    @classmethod
    def username_valid(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 3:
            raise ValueError("Username kamida 3 belgi bo'lishi kerak")
        return v

    @field_validator("password")
    @classmethod
    def password_valid(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Parol kamida 6 belgi bo'lishi kerak")
        return v


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None


# ─── Asar ─────────────────────────────────────────────────────────────────────

class AsarPageMeta(BaseModel):
    id: int
    page_number: int
    title: Optional[str]
    word_count: int
    has_quiz: bool

    model_config = {"from_attributes": True}


class AsarOut(BaseModel):
    id: int
    title: str
    title_uz: str
    slug: str
    description: Optional[str]
    category: AsarCategory
    image_url: Optional[str]
    year: Optional[int]
    language: str
    tags: List[str]
    read_count: int
    total_pages: int
    version: int
    checksum: Optional[str]
    is_published: bool
    updated_at: datetime
    created_at: datetime
    pages: List[AsarPageMeta] = []

    model_config = {"from_attributes": True}


class AsarCreate(BaseModel):
    title: str
    title_uz: str
    description: Optional[str] = None
    category: AsarCategory
    image_url: Optional[str] = None
    year: Optional[int] = None
    language: str = "uz"
    tags: List[str] = []


class AsarUpdate(BaseModel):
    title: Optional[str] = None
    title_uz: Optional[str] = None
    description: Optional[str] = None
    category: Optional[AsarCategory] = None
    image_url: Optional[str] = None
    year: Optional[int] = None
    tags: Optional[List[str]] = None
    is_published: Optional[bool] = None


# ─── Content JSON structure ───────────────────────────────────────────────────

class QuizInContent(BaseModel):
    id: int
    question: str
    type: QuizType
    options: List[str]
    correct_answers: List[int]
    explanation: Optional[str]
    difficulty: int
    points: int


class PageContent(BaseModel):
    page_number: int
    title: Optional[str]
    content: str                      # Sahifa matni
    word_count: int
    quizzes: List[QuizInContent] = []


class AsarContentJSON(BaseModel):
    """JSON fayldagi to'liq asar tuzilmasi."""
    asar_id: int
    slug: str
    title: str
    version: int
    checksum: str
    total_pages: int
    language: str
    pages: List[PageContent]


# ─── Sher ─────────────────────────────────────────────────────────────────────

class SherOut(BaseModel):
    id: int
    title: str
    slug: str
    content: str
    type: SherType
    description: Optional[str]
    asar_id: Optional[int]
    asar_title: Optional[str] = None
    audio_url: Optional[str]
    like_count: int
    is_published: bool
    version: int
    updated_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class SherCreate(BaseModel):
    title: str
    content: str
    type: SherType
    description: Optional[str] = None
    asar_id: Optional[int] = None
    audio_url: Optional[str] = None


# ─── Quiz ─────────────────────────────────────────────────────────────────────

class QuizOut(BaseModel):
    id: int
    page_id: int
    question: str
    type: QuizType
    options: List[str]
    correct_answers: List[int]
    explanation: Optional[str]
    difficulty: int
    points: int
    order_index: int

    model_config = {"from_attributes": True}


class QuizCreate(BaseModel):
    page_id: int
    question: str
    type: QuizType = QuizType.single
    options: List[str]
    correct_answers: List[int]
    explanation: Optional[str] = None
    difficulty: int = 1
    points: int = 10


class QuizSubmit(BaseModel):
    quiz_id: int
    selected_answers: List[int]
    time_spent_seconds: int = 0


class QuizSubmitResult(BaseModel):
    quiz_id: int
    is_correct: bool
    points_earned: int
    correct_answers: List[int]
    explanation: Optional[str]


# ─── Read Progress ────────────────────────────────────────────────────────────

class ReadProgressOut(BaseModel):
    asar_id: int
    current_page: int
    total_pages: int
    scroll_offset: float
    is_completed: bool
    last_read_at: datetime

    model_config = {"from_attributes": True}


class ReadProgressUpdate(BaseModel):
    asar_id: int
    current_page: int
    scroll_offset: float = 0.0
    is_completed: bool = False


# ─── Favorites ────────────────────────────────────────────────────────────────

class FavoriteToggle(BaseModel):
    content_type: str          # "asar" | "sher"
    content_id: int


# ─── Sync ─────────────────────────────────────────────────────────────────────

class SyncItemMeta(BaseModel):
    id: int
    slug: str
    content_type: str
    version: int
    checksum: str
    file_size_bytes: int
    updated_at: datetime


class SyncManifestResponse(BaseModel):
    """Client bu manifest orqali nimani yuklab olishini biladi."""
    bundle_version: int
    generated_at: datetime
    asarlar: List[SyncItemMeta]
    sherlar: List[SyncItemMeta]
    total_items: int


class SyncCheckRequest(BaseModel):
    """Client o'zida bor versiyalarni yuboradi."""
    local_versions: Dict[str, int]    # {"asar_slug": version, ...}


class SyncCheckResponse(BaseModel):
    """Server qaysilarini yangilash kerakligini aytadi."""
    needs_update: List[SyncItemMeta]
    up_to_date: List[str]           # slug list


# ─── Statistics ───────────────────────────────────────────────────────────────

class UserStats(BaseModel):
    total_read: int
    completed: int
    in_progress: int
    total_quiz_answered: int
    correct_answers: int
    total_points: int
    favorite_count: int
