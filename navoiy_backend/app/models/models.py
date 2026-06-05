# app/models/models.py
from sqlalchemy import (
    Column, Integer, String, Text, Boolean, DateTime,
    ForeignKey, JSON, Float, Enum as SAEnum, UniqueConstraint, Index
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..db.database import Base
import enum


# ─── Enums ────────────────────────────────────────────────────────────────────

class UserRole(str, enum.Enum):
    admin = "admin"
    moderator = "moderator"
    user = "user"


class AsarCategory(str, enum.Enum):
    doston = "doston"
    gazal = "gazal"
    ruboiy = "ruboiy"
    qasida = "qasida"
    ilmiy = "ilmiy"
    boshqa = "boshqa"


class SherType(str, enum.Enum):
    gazal = "gazal"
    ruboiy = "ruboiy"
    qita = "qita"
    hikmat = "hikmat"
    nazm = "nazm"
    boshqa = "boshqa"


class QuizType(str, enum.Enum):
    single = "single"      # Bitta to'g'ri javob
    multiple = "multiple"  # Ko'p to'g'ri javob
    truefalse = "truefalse"


# ─── User ─────────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    full_name = Column(String(150), nullable=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(SAEnum(UserRole), default=UserRole.user, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    avatar_url = Column(String(500), nullable=True)
    last_login = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    read_progress = relationship("ReadProgress", back_populates="user", cascade="all, delete-orphan")
    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")
    quiz_results = relationship("QuizResult", back_populates="user", cascade="all, delete-orphan")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(String(255), unique=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    device_info = Column(String(255), nullable=True)

    user = relationship("User", back_populates="refresh_tokens")


# ─── Asar ─────────────────────────────────────────────────────────────────────

class Asar(Base):
    __tablename__ = "asarlar"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(300), nullable=False)
    title_uz = Column(String(300), nullable=False)
    slug = Column(String(300), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    category = Column(SAEnum(AsarCategory), nullable=False, index=True)

    # Content stored as JSON file reference
    # Full content is in: content/asarlar/{slug}.json
    content_file = Column(String(500), nullable=True)   # path to JSON file
    total_pages = Column(Integer, default=1)             # Sahifalar soni

    image_url = Column(String(500), nullable=True)
    year = Column(Integer, nullable=True)
    language = Column(String(20), default="uz")
    tags = Column(JSON, default=list)
    read_count = Column(Integer, default=0)
    is_published = Column(Boolean, default=True)

    # Sync metadata
    version = Column(Integer, default=1)                 # Content versiyasi
    checksum = Column(String(64), nullable=True)         # SHA256 of content JSON
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    sherlar = relationship("Sher", back_populates="asar", cascade="all, delete-orphan")
    pages = relationship("AsarPage", back_populates="asar", cascade="all, delete-orphan", order_by="AsarPage.page_number")
    favorites = relationship("Favorite", back_populates="asar")
    read_progress = relationship("ReadProgress", back_populates="asar")


class AsarPage(Base):
    """Asarning har bir sahifasi — JSON faylda saqlanadi, bu faqat meta."""
    __tablename__ = "asar_pages"

    id = Column(Integer, primary_key=True, index=True)
    asar_id = Column(Integer, ForeignKey("asarlar.id", ondelete="CASCADE"), nullable=False)
    page_number = Column(Integer, nullable=False)
    title = Column(String(300), nullable=True)           # Bob nomi
    word_count = Column(Integer, default=0)
    has_quiz = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    asar = relationship("Asar", back_populates="pages")
    quizzes = relationship("Quiz", back_populates="page", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("asar_id", "page_number"),
    )


# ─── Sher ─────────────────────────────────────────────────────────────────────

class Sher(Base):
    __tablename__ = "sherlar"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(300), nullable=False)
    slug = Column(String(300), unique=True, nullable=False, index=True)
    content = Column(Text, nullable=False)               # Qisqa she'r — DB da
    type = Column(SAEnum(SherType), nullable=False, index=True)
    description = Column(Text, nullable=True)
    asar_id = Column(Integer, ForeignKey("asarlar.id", ondelete="SET NULL"), nullable=True)
    audio_url = Column(String(500), nullable=True)
    like_count = Column(Integer, default=0)
    is_published = Column(Boolean, default=True)
    version = Column(Integer, default=1)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    asar = relationship("Asar", back_populates="sherlar")
    favorites = relationship("Favorite", back_populates="sher")


# ─── Quiz ─────────────────────────────────────────────────────────────────────

class Quiz(Base):
    """Sahifa uchun savollar."""
    __tablename__ = "quizlar"

    id = Column(Integer, primary_key=True, index=True)
    page_id = Column(Integer, ForeignKey("asar_pages.id", ondelete="CASCADE"), nullable=False)
    question = Column(Text, nullable=False)
    type = Column(SAEnum(QuizType), default=QuizType.single)
    options = Column(JSON, nullable=False)               # ["A", "B", "C", "D"]
    correct_answers = Column(JSON, nullable=False)       # [0] yoki [0, 2]
    explanation = Column(Text, nullable=True)            # To'g'ri javob izohi
    difficulty = Column(Integer, default=1)              # 1=oson, 2=o'rta, 3=qiyin
    points = Column(Integer, default=10)
    order_index = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    page = relationship("AsarPage", back_populates="quizzes")
    results = relationship("QuizResult", back_populates="quiz")


class QuizResult(Base):
    """Foydalanuvchi quiz natijasi."""
    __tablename__ = "quiz_results"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    quiz_id = Column(Integer, ForeignKey("quizlar.id", ondelete="CASCADE"), nullable=False)
    selected_answers = Column(JSON, nullable=False)
    is_correct = Column(Boolean, nullable=False)
    points_earned = Column(Integer, default=0)
    time_spent_seconds = Column(Integer, default=0)
    answered_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="quiz_results")
    quiz = relationship("Quiz", back_populates="results")


# ─── Read Progress ────────────────────────────────────────────────────────────

class ReadProgress(Base):
    """O'qish progressi — qaysi sahifada qolganini saqlaydi."""
    __tablename__ = "read_progress"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    asar_id = Column(Integer, ForeignKey("asarlar.id", ondelete="CASCADE"), nullable=False)
    current_page = Column(Integer, default=1)
    total_pages = Column(Integer, default=1)
    scroll_offset = Column(Float, default=0.0)           # Sahifa ichidagi o'rin (0.0-1.0)
    is_completed = Column(Boolean, default=False)
    last_read_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    started_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="read_progress")
    asar = relationship("Asar", back_populates="read_progress")

    __table_args__ = (
        UniqueConstraint("user_id", "asar_id"),
        Index("ix_read_progress_user", "user_id"),
    )


# ─── Favorites ────────────────────────────────────────────────────────────────

class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    asar_id = Column(Integer, ForeignKey("asarlar.id", ondelete="SET NULL"), nullable=True)
    sher_id = Column(Integer, ForeignKey("sherlar.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")
    asar = relationship("Asar", back_populates="favorites")
    sher = relationship("Sher", back_populates="favorites")

    __table_args__ = (
        UniqueConstraint("user_id", "asar_id"),
        UniqueConstraint("user_id", "sher_id"),
    )


# ─── Sync Manifest ────────────────────────────────────────────────────────────

class SyncManifest(Base):
    """Client qaysi versiyani yuklab olganini kuzatish uchun."""
    __tablename__ = "sync_manifests"

    id = Column(Integer, primary_key=True)
    bundle_version = Column(Integer, nullable=False)
    content_type = Column(String(50), nullable=False)    # "asarlar" | "sherlar"
    item_id = Column(Integer, nullable=False)
    item_slug = Column(String(300), nullable=False)
    checksum = Column(String(64), nullable=False)
    file_size_bytes = Column(Integer, default=0)
    updated_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("content_type", "item_id"),
        Index("ix_sync_bundle_version", "bundle_version"),
    )

class AppSetting(Base):
    __tablename__ = "app_settings"

    id = Column(Integer, primary_key=True)
    key = Column(String(50), unique=True, nullable=False)  # 'bot_token', 'chat_id'
    value = Column(Text, nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())