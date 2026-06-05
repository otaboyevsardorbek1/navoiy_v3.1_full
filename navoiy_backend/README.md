# Navoiy Asarlari — FastAPI Backend

> **Guvohnoma:** № DGU 53808 | O'zbekiston Respublikasi Adliya Vazirligi

---

## 🚀 Tez ishga tushirish

### 1. Docker bilan (tavsiya etiladi)

```bash
cd navoiy_backend
cp .env.example .env
docker-compose up -d
python scripts/seed.py    # Ma'lumot yuklash
```

API: http://localhost:8000  
Docs: http://localhost:8000/docs

---

### 2. Qo'lda (PostgreSQL kerak)

```bash
cd navoiy_backend
pip install -r requirements.txt

# .env faylni sozlash
cp .env.example .env
# DATABASE_URL ni o'zgartiring

# Ma'lumotlar bazasini yaratish
createdb navoiy_db

# Serverni ishga tushirish
uvicorn app.main:app --reload --port 8000

# Ma'lumot yuklash (alohida terminalda)
python scripts/seed.py
```

---

## 📡 API Endpointlar

### 🔐 Auth
| Method | URL | Tavsif |
|--------|-----|--------|
| POST | `/api/v1/auth/login` | Tizimga kirish → JWT token |
| POST | `/api/v1/auth/refresh` | Token yangilash |
| POST | `/api/v1/auth/logout` | Chiqish |
| POST | `/api/v1/auth/register` | Ro'yxatdan o'tish |
| GET | `/api/v1/auth/me` | Joriy foydalanuvchi |

### 📚 Asarlar
| Method | URL | Tavsif |
|--------|-----|--------|
| GET | `/api/v1/asarlar` | Ro'yxat (filter, search, page) |
| GET | `/api/v1/asarlar/{slug}` | Bitta asar meta |
| GET | `/api/v1/asarlar/{slug}/content` | To'liq JSON kontent |
| GET | `/api/v1/asarlar/{slug}/page/{n}` | Bitta sahifa |
| POST | `/api/v1/asarlar` | Yaratish (Admin) |
| PATCH | `/api/v1/asarlar/{slug}` | Tahrirlash (Admin) |
| DELETE | `/api/v1/asarlar/{slug}` | O'chirish (Admin) |
| POST | `/api/v1/asarlar/{slug}/content` | Kontent yuklash (Admin) |

### 📜 She'rlar
| Method | URL | Tavsif |
|--------|-----|--------|
| GET | `/api/v1/sherlar` | Ro'yxat |
| GET | `/api/v1/sherlar/{slug}` | Bitta she'r |
| POST | `/api/v1/sherlar` | Yaratish (Admin) |
| POST | `/api/v1/sherlar/{id}/favorite` | Yoqtirish toggle |

### 🔄 Sinxronizatsiya
| Method | URL | Tavsif |
|--------|-----|--------|
| GET | `/api/v1/sync/manifest` | Barcha kontentlar ro'yxati |
| POST | `/api/v1/sync/check` | Delta tekshirish |
| GET | `/api/v1/sync/download/asar/{slug}` | Asar JSON yuklab olish |
| GET | `/api/v1/sync/download/sherlar` | She'rlar bundle |
| POST | `/api/v1/sync/progress` | O'qish progressini saqlash |
| GET | `/api/v1/sync/progress` | Barcha progressni olish |

### ❓ Quiz
| Method | URL | Tavsif |
|--------|-----|--------|
| POST | `/api/v1/quiz/submit` | Javob yuborish |
| POST | `/api/v1/quiz` | Savol yaratish (Admin) |

---

## 🔑 Demo hisoblar

| Login | Parol | Rol |
|-------|-------|-----|
| admin | admin123 | Administrator |
| user | user123 | Foydalanuvchi |

---

## 📦 Texnologiyalar

- **FastAPI** — asosiy framework
- **SQLAlchemy 2.0** — async ORM
- **PostgreSQL** — ma'lumotlar bazasi
- **JWT** — autentifikatsiya (access + refresh token)
- **Alembic** — migratsiyalar
- **Docker** — konteynerizatsiya

---

## 🗂️ Loyiha tuzilmasi

```
navoiy_backend/
├── app/
│   ├── api/v1/endpoints/
│   │   ├── auth.py       # Login, refresh, logout
│   │   ├── asarlar.py    # CRUD + content upload
│   │   ├── sherlar.py    # She'rlar + quiz
│   │   └── sync.py       # Offline sync + progress
│   ├── core/
│   │   ├── config.py     # .env sozlamalari
│   │   ├── security.py   # JWT, bcrypt
│   │   └── dependencies.py # Auth middleware
│   ├── db/database.py    # SQLAlchemy engine
│   ├── models/models.py  # DB modellari
│   ├── schemas/schemas.py # Pydantic schemalar
│   ├── services/content_service.py # JSON fayl boshqaruvi
│   └── main.py           # FastAPI app
├── scripts/seed.py       # DB to'ldirish
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── .env.example
```

---

## 🔗 Flutter bilan ulash

Flutter ilovasida Settings → Online rejim → API URL:
```
http://YOUR_SERVER_IP:8000/api/v1
```

Mahalliy test uchun:
```
http://10.0.2.2:8000/api/v1    # Android emulator
http://localhost:8000/api/v1   # iOS simulator
```
