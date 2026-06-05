# app/api/v1/router.py
from fastapi import APIRouter
from .endpoints.auth import router as auth_router
from .endpoints.asarlar import router as asarlar_router
from .endpoints.sherlar import router as sherlar_router, quiz_router
from .endpoints.sync import router as sync_router
from .endpoints.settings import router as settings_router
from .endpoints.logs import router as logs_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(asarlar_router)
api_router.include_router(sherlar_router)
api_router.include_router(quiz_router)
api_router.include_router(sync_router)
api_router.include_router(settings_router)
api_router.include_router(logs_router)
