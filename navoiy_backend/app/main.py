# app/main.py
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
import socket
import requests
import subprocess
import sys
import json
from typing import Optional, Dict, Any

from .core.config import settings
from .api.v1.router import api_router
from .db.database import engine, Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def get_local_ip() -> str:
    """Lokal tarmoq IP manzilini olish"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def get_public_ip() -> Optional[str]:
    """Tashqi (publik) IP manzilini olish"""
    try:
        response = requests.get("https://api.ipify.org?format=json", timeout=5)
        if response.status_code == 200:
            return response.json().get("ip")
        return None
    except Exception:
        try:
            # Alternativ xizmat
            response = requests.get("https://ifconfig.me/ip", timeout=5)
            if response.status_code == 200:
                return response.text.strip()
            return None
        except Exception:
            return None


def check_ngrok_status() -> Optional[str]:
    """Ngrok holatini tekshirish va URL olish"""
    try:
        result = subprocess.run(
            ["curl", "-s", "http://127.0.0.1:4040/api/tunnels"],
            capture_output=True, text=True, timeout=3
        )
        if result.returncode == 0 and result.stdout:
            data = json.loads(result.stdout)
            tunnels = data.get("tunnels", [])
            for tunnel in tunnels:
                if tunnel.get("proto") == "https":
                    return tunnel.get("public_url")
            # Agar HTTPS bo'lmasa, HTTP ni qaytar
            for tunnel in tunnels:
                if tunnel.get("proto") == "http":
                    return tunnel.get("public_url")
        return None
    except Exception:
        return None


def check_localtunnel_status() -> Optional[str]:
    """Localtunnel holatini tekshirish"""
    try:
        # Localtunnel odatda subdomain.localhost.run formatida bo'ladi
        result = subprocess.run(
            ["pgrep", "-f", "lt --port 8000"],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0:
            # URL ni fayldan o'qish
            lt_file = "/tmp/lt_url.txt"
            try:
                with open(lt_file, "r") as f:
                    return f.read().strip()
            except:
                pass
        return None
    except Exception:
        return None


def get_all_network_interfaces() -> Dict[str, Any]:
    """Barcha tarmoq interfeyslarini olish"""
    interfaces = {}
    try:
        hostname = socket.gethostname()
        interfaces["hostname"] = hostname
        
        # Barcha IP manzillarni olish
        all_ips = []
        try:
            # socket orqali
            all_ips.append(("localhost", "127.0.0.1"))
            local_ip = get_local_ip()
            if local_ip != "127.0.0.1":
                all_ips.append(("primary", local_ip))
            
            # Boshqa interfeyslarni olish
            result = subprocess.run(
                ["hostname", "-I"],
                capture_output=True, text=True, timeout=2
            )
            if result.returncode == 0 and result.stdout:
                ips = result.stdout.strip().split()
                for i, ip in enumerate(ips):
                    if ip != local_ip and ip != "127.0.0.1":
                        all_ips.append((f"interface_{i}", ip))
        except Exception:
            pass
        
        interfaces["ips"] = all_ips
        interfaces["local_primary"] = get_local_ip()
    except Exception:
        pass
    
    return interfaces


def print_server_info():
    """Server ma'lumotlarini chiqarish"""
    local_ip = get_local_ip()
    public_ip = get_public_ip()
    ngrok_url = check_ngrok_status()
    lt_url = check_localtunnel_status()
    
    print("\n" + "=" * 70)
    print("🚀 NAVOIY API SERVER ISHGA TUSHIRILDI!")
    print("=" * 70)
    
    print("\n📍 LOKAL MANZILLAR:")
    print(f"   • API:           http://localhost:8000")
    print(f"   • API:           http://127.0.0.1:8000")
    print(f"   • Swagger UI:    http://localhost:8000/docs")
    print(f"   • ReDoc:         http://localhost:8000/redoc")
    print(f"   • Server Info:   http://localhost:8000/server-info")
    print(f"   • Health Check:  http://localhost:8000/health")
    
    print(f"\n🌐 LOKAL TARMOQ MANZILI:")
    print(f"   • API:           http://{local_ip}:8000")
    print(f"   • Swagger UI:    http://{local_ip}:8000/docs")
    print(f"   • Server Info:   http://{local_ip}:8000/server-info")
    
    if public_ip:
        print(f"\n🌍 TASHQI IP MANZIL (Agar port ochiq bo'lsa):")
        print(f"   • API:           http://{public_ip}:8000")
        print(f"   • Swagger UI:    http://{public_ip}:8000/docs")
        print(f"   • Server Info:   http://{public_ip}:8000/server-info")
        print(f"\n   ⚠️  Eslatma: Routerda 8000-port forward qilingan bo'lishi kerak!")
        print(f"   ⚠️  Firewall: sudo ufw allow 8000/tcp")
    
    if ngrok_url:
        print(f"\n🔗 NGROK TUNNEL (Internet orqali xavfsiz):")
        print(f"   • API:           {ngrok_url}")
        print(f"   • Swagger UI:    {ngrok_url}/docs")
        print(f"   • Server Info:   {ngrok_url}/server-info")
    
    if lt_url:
        print(f"\n🔗 LOCALTUNNEL (Internet orqali):")
        print(f"   • API:           {lt_url}")
        print(f"   • Swagger UI:    {lt_url}/docs")
    
    print("\n" + "-" * 70)
    print("📋 API ENDPOINTLARI:")
    print("-" * 70)
    print("  AUTH:")
    print("    POST /api/v1/auth/login      - Tizimga kirish")
    print("    POST /api/v1/auth/register   - Ro'yxatdan o'tish")
    print("    POST /api/v1/auth/refresh    - Token yangilash")
    print("    POST /api/v1/auth/logout     - Chiqish")
    print("    GET  /api/v1/auth/me         - Joriy foydalanuvchi")
    print()
    print("  ASARLAR:")
    print("    GET  /api/v1/asarlar              - Barcha asarlar")
    print("    GET  /api/v1/asarlar/{slug}       - Asar ma'lumoti")
    print("    GET  /api/v1/asarlar/{slug}/content - Asar kontenti (JSON)")
    print("    GET  /api/v1/asarlar/{slug}/page/{n} - Sahifa kontenti")
    print()
    print("  SHERLAR:")
    print("    GET  /api/v1/sherlar              - Barcha she'rlar")
    print("    GET  /api/v1/sherlar/{slug}       - She'r ma'lumoti")
    print()
    print("  QUIZ:")
    print("    POST /api/v1/quiz/submit          - Quiz javobini yuborish")
    print()
    print("  SYNC:")
    print("    GET  /api/v1/sync/manifest        - Sinxronizatsiya manifesti")
    print("    POST /api/v1/sync/check           - Versiyalarni tekshirish")
    print("    GET  /api/v1/sync/download/asar/{slug} - Asarni yuklab olish")
    print("    POST /api/v1/sync/progress        - O'qish progressini saqlash")
    print()
    print("  ADMIN:")
    print("    GET  /api/v1/admin/settings       - Sozlamalar")
    print("    POST /api/v1/admin/settings       - Sozlamani yangilash")
    
    print("\n" + "=" * 70)
    print("👤 TEST FOYDALANUVCHILAR:")
    print("=" * 70)
    print("   • Admin: admin / admin123")
    print("   • User:  user / user123")
    print()
    print("🔐 LOGIN UCHUN:")
    print("   curl -X POST http://localhost:8000/api/v1/auth/login \\")
    print("        -H \"Content-Type: application/json\" \\")
    print("        -d '{\"username\":\"admin\",\"password\":\"admin123\"}'")
    print()
    print("=" * 70)
    print("🌐 Tashqi ulanish uchun ngrok tavsiya etiladi:")
    print("   ngrok http 8000")
    print("=" * 70 + "\n")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 Navoiy API ishga tushmoqda...")
    
    # Server ma'lumotlarini chiqarish
    print_server_info()
    
    # DB jadvallarini yaratish
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("✅ Database tayyor")
    except Exception as e:
        logger.error(f"❌ Database xatosi: {e}")
        logger.warning("⚠️  PostgreSQL ishlayotganini tekshiring!")
    
    yield
    
    logger.info("🛑 Server to'xtamoqda...")
    try:
        await engine.dispose()
    except Exception:
        pass


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="""
## 📚 Navoiy Asarlari API

Alisher Navoiy asarlarini o'rganish platformasi uchun backend API.

### 🔐 Autentifikatsiya
Barcha himoyalangan endpointlar uchun **Bearer Token** kerak. 
Login qilgandan so'ng `access_token` ni `Authorization: Bearer <token>` headerida yuboring.

### 📱 Offline/Online Sync
Flutter ilova uchun to'liq offline qo'llab-quvvatlash:
- `/sync/manifest` - barcha kontent versiyalari
- `/sync/download/*` - JSON formatda kontent yuklash
- `/sync/progress` - o'qish progressini serverga yuborish

### 🧪 Test Uchun
- Admin: `admin / admin123`
- Foydalanuvchi: `user / user123`
- `/server-info` - server ulanish ma'lumotlari
    """,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
    contact={
        "name": "Navoiy API Support",
        "email": "support@navoiy.uz",
    },
    license_info={
        "name": "MIT",
    },
)

# ─── Middleware ───────────────────────────────────────────────────────────────

app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Content-Version", "X-Content-Checksum", "X-Content-Slug"],
)

# ─── Global exception handler ─────────────────────────────────────────────────

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Server ichki xatosi",
            "path": str(request.url),
        },
    )


@app.exception_handler(404)
async def not_found_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "detail": "So'ralgan manzil topilmadi",
            "path": str(request.url),
            "available_endpoints": [
                "/docs",
                "/redoc",
                "/server-info",
                "/health",
                "/api/v1/auth/login",
                "/api/v1/asarlar",
                "/api/v1/sherlar",
            ]
        },
    )

# ─── Routes ───────────────────────────────────────────────────────────────────

app.include_router(api_router, prefix=settings.API_V1_PREFIX)


# ─── Info Endpoints ───────────────────────────────────────────────────────────

@app.get("/", tags=["info"])
async def root():
    """Asosiy ma'lumot"""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs",
        "redoc": "/redoc",
        "server_info": "/server-info",
        "health": "/health",
    }


@app.get("/health", tags=["info"])
async def health():
    """Health check endpoint"""
    # Database holatini tekshirish
    db_status = "unknown"
    try:
        async with engine.connect() as conn:
            await conn.execute(Base.metadata.tables.keys()) # type: ignore
        db_status = "connected"
    except Exception:
        db_status = "disconnected"
    
    return {
        "status": "ok",
        "version": settings.APP_VERSION,
        "database": db_status,
        "timestamp": __import__("datetime").datetime.now().isoformat(),
    }


@app.get("/server-info", tags=["info"])
async def server_info():
    """Server ma'lumotlari va ulanish manzillari"""
    local_ip = get_local_ip()
    public_ip = get_public_ip()
    ngrok_url = check_ngrok_status()
    lt_url = check_localtunnel_status()
    interfaces = get_all_network_interfaces()
    
    result = {
        "server": {
            "name": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "hostname": interfaces.get("hostname", socket.gethostname()),
        },
        "local": {
            "localhost": "http://localhost:8000",
            "network_primary": f"http://{local_ip}:8000",
            "docs": "http://localhost:8000/docs",
            "server_info": "http://localhost:8000/server-info",
        },
        "network_interfaces": interfaces.get("ips", []),
        "public": {
            "ip": public_ip,
            "url": f"http://{public_ip}:8000" if public_ip else None,
            "docs": f"http://{public_ip}:8000/docs" if public_ip else None,
            "note": "Routerda 8000-port forward qilingan bo'lishi kerak!" if public_ip else None,
        } if public_ip else None,
        "tunnels": {},
        "test_credentials": {
            "admin": {"username": "admin", "password": "admin123"},
            "user": {"username": "user", "password": "user123"},
        },
        "endpoints": {
            "auth_login": "/api/v1/auth/login",
            "asarlar": "/api/v1/asarlar",
            "sherlar": "/api/v1/sherlar",
            "sync_manifest": "/api/v1/sync/manifest",
            "docs": "/docs",
            "openapi": "/openapi.json",
        },
        "curl_examples": {
            "login": "curl -X POST http://localhost:8000/api/v1/auth/login -H \"Content-Type: application/json\" -d '{\"username\":\"admin\",\"password\":\"admin123\"}'",
            "asarlar": "curl -X GET http://localhost:8000/api/v1/asarlar -H \"Authorization: Bearer YOUR_TOKEN\"",
        }
    }
    
    if ngrok_url:
        result["tunnels"]["ngrok"] = {
            "url": ngrok_url,
            "docs": f"{ngrok_url}/docs",
            "server_info": f"{ngrok_url}/server-info",
        }
    
    if lt_url:
        result["tunnels"]["localtunnel"] = {
            "url": lt_url,
            "docs": f"{lt_url}/docs",
        }
    
    return result


@app.get("/ping", tags=["info"])
async def ping():
    """Oddiy ping endpoint"""
    return {"ping": "pong", "timestamp": __import__("time").time()}