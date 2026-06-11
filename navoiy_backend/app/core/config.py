# app/core/config.py
from pydantic_settings import BaseSettings
from typing import Optional, List  
import secrets


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Navoiy Asarlari API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24        # 24 soat
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30               # 30 kun

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/navoiy_db"
    DATABASE_URL_SYNC: str = "postgresql://postgres:postgres@localhost:5432/navoiy_db"
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "*",  # Flutter mobile uchun
    ]

    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # File storage (JSON content files)
    CONTENT_DIR: str = "content"   # ./content/asarlar/, ./content/sherlar/

    # Sync
    SYNC_BUNDLE_VERSION: int = 1   # Har full sync da oshiriladi
    # Email settings
    SMTP_SERVER: str = "smtp.gmail.com"
    SMTP_PORT: int = 465
    SMTP_USERNAME: str = "otaboyevsardorbek295@gmail.com"      # Gmail manzili
    SMTP_PASSWORD: str = "pvkl fcme yznf ujom "         # Gmail app paroli
    SMTP_FROM_EMAIL: str = "otaboyevsardorbek295@gmail.com"
    FRONTEND_URL: str = "http://localhost:5500"      # Frontend manzili

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
