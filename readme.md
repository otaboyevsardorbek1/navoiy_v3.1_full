# NAVOIY V3.1 FULL

## Alisher Navoiy Digital Ecosystem

Kompleks raqamli platforma bo‘lib, Alisher Navoiy merosini zamonaviy texnologiyalar yordamida o‘rganish, saqlash va targ‘ib qilish uchun ishlab chiqilgan.

Platforma quyidagi komponentlardan tashkil topgan:

* Android Native Application (Java)
* Flutter Mobile Application
* FastAPI Backend
* PostgreSQL Database
* Docker Infrastructure
* Offline Content Engine
* Synchronization System
* Analytics & Progress Tracking

---

# System Architecture

```text
┌───────────────────────────────┐
│        Mobile Clients         │
├───────────────┬───────────────┤
│ Android(Java)│ Flutter(Dart) │
└───────┬───────┴───────┬───────┘
        │ REST API
        ▼
┌───────────────────────────────┐
│        FastAPI Backend        │
├───────────────────────────────┤
│ Authentication (JWT)          │
│ Content Management            │
│ Progress Tracking             │
│ Leaderboard                   │
│ Analytics                     │
│ Synchronization               │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│         PostgreSQL            │
└───────────────────────────────┘
```

---

# Repository Structure

```text
navoiy_v3.1_full/

├── navoiy_backend/
│   ├── app/
│   │   ├── api/
│   │   ├── core/
│   │   ├── db/
│   │   ├── models/
│   │   ├── schemas/
│   │   └── services/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── navoiy_app/
│   └── Flutter Application
│
├── Alisher_Navoiy_app_androyid/
│   └── Native Android Application
│
└── Content Files
    ├── Farhod va Shirin
    ├── Layli va Majnun
    ├── Hayrat ul-Abror
    ├── Sab'ai Sayyor
    ├── Saddi Iskandariy
    └── Badoyi' ul-Vasat
```

---

# Technology Stack

## Backend

* FastAPI 0.111
* SQLAlchemy 2.0
* Alembic
* AsyncPG
* PostgreSQL
* JWT Authentication
* Pydantic v2
* Uvicorn

## Mobile

### Android Native

* Java
* Android SDK
* RecyclerView
* Fragments
* SQLite
* WorkManager

### Flutter

* Flutter 3+
* Dart 3+
* Dio
* GoRouter
* SQLite
* Bloc Pattern

---

# Features

## Authentication

* User Registration
* Login
* JWT Token
* Session Management
* Password Recovery

## Literary Content

* Alisher Navoiy asarlari
* Xamsa kolleksiyasi
* G‘azallar
* She'rlar
* Izohlar
* Lug‘at

## Learning System

* Reading Progress
* Statistics
* User Ranking
* Leaderboard
* Achievement Tracking

## Synchronization

* Offline First
* Data Sync
* Incremental Updates
* Content Version Control

## Administration

* User Management
* Content Management
* Statistics Dashboard
* Monitoring

---

# Android Native Application

## Main Activities

* SplashActivity
* LoginActivity
* RegisterActivity
* MainActivity
* AdminActivity
* SettingsActivity
* ForgotPasswordActivity
* AsarReaderActivity

## Fragments

* AsarlarFragment
* SherlarFragment
* LeaderboardFragment
* ProfileFragment
* SettingsFragment
* SyncFragment

## Services

* ApiService
* NetworkClient
* TelegramService
* SyncManager
* SessionManager
* ProgressManager

---

# Flutter Application

## Core

* Routing
* Theme Management
* Network Layer
* Error Handling

## Data Layer

* Local Storage
* Remote API
* Repository Pattern

## Presentation

* Authentication
* Home
* Asarlar
* Sherlar
* Settings

---

# Backend Components

## API Layer

RESTful API endpoints.

## Database Layer

SQLAlchemy ORM.

## Services Layer

Business logic implementation.

## Authentication Layer

JWT based security.

## Content Engine

Literary resource management.

---

# Database

PostgreSQL 16

Default Database:

```env
POSTGRES_DB=navoiy_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

---

# Docker Deployment

## Start Services

```bash
docker-compose up -d
```

## Stop Services

```bash
docker-compose down
```

## Rebuild

```bash
docker-compose up --build
```

---

# Backend Installation

```bash
cd navoiy_backend

python -m venv venv

source venv/bin/activate

pip install -r requirements.txt

uvicorn app.main:app --reload
```

Backend URL:

```text
http://localhost:8000
```

---

# Flutter Installation

```bash
cd navoiy_app

flutter pub get

flutter run
```

---

# Android Studio Installation

```bash
Open:
Alisher_Navoiy_app_androyid/

Sync Gradle

Run Application
```

Minimum SDK:

```text
Android 5.0+
```

---

# Environment Variables

```env
DATABASE_URL=
DATABASE_URL_SYNC=

SECRET_KEY=

DEBUG=false

CONTENT_DIR=/app/content
```

---

# Security

* JWT Authentication
* Password Hashing
* Secure Session Storage
* API Validation
* Role Based Access

---

# Monitoring

* Application Logs
* User Activity Tracking
* Reading Statistics
* Error Tracking

---

# Content Sources

Platform quyidagi asarlarni qo‘llab-quvvatlaydi:

* Farhod va Shirin
* Layli va Majnun
* Hayrat ul-Abror
* Sab'ai Sayyor
* Saddi Iskandariy
* Badoyi' ul-Vasat

---

# Development Roadmap

* AI Search
* Smart Recommendations
* Voice Reading
* OCR Integration
* Advanced Analytics
* Cloud Synchronization
* Multi-language Support

---

# License

Copyright © Navoiy V3.1 Full

All Rights Reserved.

---

# Author

ProDevUzOff

Alisher Navoiy Digital Heritage Platform
