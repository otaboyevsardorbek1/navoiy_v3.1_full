# Navoiy Asarlari — Flutter ilovasi

> **Guvohnoma:** № DGU 53808 | O'zbekiston Respublikasi Adliya Vazirligi  
> **Mualliflar:** Karimov Nodirbek Nosirjon o'g'li & Burxonova Madinabonu Sayidkamol qizi

---

## 📱 Ilova haqida

Alisher Navoiy asarlarini integratsion yondashuv asosida o'rganishga mo'ljallangan to'liq funksional Flutter mobil ilovasi.

---

## 🏗️ Arxitektura

```
lib/
├── core/
│   ├── constants/      # App doimiy qiymatlari
│   ├── network/        # Dio, ApiClient, AuthService, ConnectivityService
│   ├── router/         # GoRouter konfiguratsiyasi
│   ├── theme/          # 3 ta tema (Classic, Modern, Dark)
│   └── utils/          # SettingsService, ErrorHandler
│
├── data/
│   ├── datasources/
│   │   ├── local/      # SQLite (DatabaseHelper)
│   │   └── remote/     # API (RemoteDataSource)
│   ├── models/         # UserModel, AsarModel, SherModel, AuthResponse
│   └── repositories/   # NavoiyRepository (offline/online switching)
│
└── presentation/
    ├── auth/           # LoginScreen + AuthBloc
    ├── splash/         # SplashScreen (animatsiyali)
    ├── home/           # HomeScreen (BottomNavBar)
    ├── asarlar/        # AsarlarScreen, AsarDetailScreen + AsarlarBloc
    ├── sherlar/        # SherlarScreen + SherlarBloc
    ├── settings/       # SettingsScreen (tema, rejim, API URL)
    └── widgets/        # Umumiy widgetlar
```

---

## ✨ Asosiy imkoniyatlar

### 🔐 Autentifikatsiya
- Login/parol orqali tizimga kirish
- JWT token saqlash (FlutterSecureStorage)
- Sessiya muddatini kuzatish va avtomatik yangilash
- Offline rejim uchun demo hisoblar

### 📚 Asarlar bo'limi
- Kategoriya bo'yicha filtrlash (doston, g'azal, ruboiy, ilmiy)
- Qidiruv
- Yoqtirish (favorites)
- To'liq matn o'qish
- Shrift o'lchami boshqaruvi

### 📜 She'rlar va G'azallar
- Tur bo'yicha filtrlash
- Kengaytiriladigan she'r kartalari
- Matnni clipboard'ga nusxalash
- Yoqtirish funksiyasi

### ⚙️ Sozlamalar
- **3 ta dizayn:** Klassik (sharqona), Modern (minimalist), Dark
- **Ishlash rejimi:** Offline ↔ Online (API) almashtirish
- **API URL** sozlash va test qilish
- Hisob ma'lumotlari va chiqish

### 🌐 Tarmoq
- Offline-first arxitektura (SQLite → API fallback)
- Connectivity monitoring + banner
- API auto token refresh
- Error handling (Uzbek tilidagi xabarlar)

---

## 🚀 O'rnatish va ishga tushirish

### Talablar
- Flutter 3.16+
- Dart 3.0+
- Android SDK 21+ yoki iOS 12+

### Qadamlar

```bash
# 1. Loyihani klonlash
git clone <repo-url>
cd navoiy_app

# 2. Bog'liqliklarni o'rnatish
flutter pub get

# 3. Ilovani ishga tushirish
flutter run

# 4. Release build (Android)
flutter build apk --release

# 5. Release build (iOS)
flutter build ipa --release
```

---

## 🔑 Demo hisoblar (Offline rejim)

| Login | Parol | Rol |
|-------|-------|-----|
| admin | admin123 | Administrator |
| user | user123 | Foydalanuvchi |

---

## 🌐 API integratsiya

Online rejimda quyidagi endpointlar kutiladi:

| Method | Endpoint | Tavsif |
|--------|----------|--------|
| POST | `/auth/login` | Tizimga kirish |
| POST | `/auth/refresh` | Token yangilash |
| GET | `/asarlar` | Asarlar ro'yxati |
| GET | `/asarlar/{id}` | Bitta asar |
| GET | `/sherlar` | She'rlar ro'yxati |
| POST | `/favorites` | Yoqtirishga qo'shish |
| DELETE | `/favorites/{type}/{id}` | Yoqtirishdan olib tashlash |

---

## 📦 Asosiy paketlar

| Paket | Maqsad |
|-------|--------|
| flutter_bloc | State management |
| go_router | Navigation |
| sqflite | Local database |
| dio | HTTP client |
| flutter_secure_storage | JWT saqlash |
| shared_preferences | Sozlamalar |
| google_fonts | Amiri, Poppins, Fira Code |
| connectivity_plus | Tarmoq holati |
| flutter_staggered_animations | List animatsiyalari |
| shimmer | Loading skeletons |

---

## 📄 Litsenziya

© 2025 Karimov Nodirbek & Burxonova Madinabonu  
Guvohnoma № DGU 53808 — O'zbekiston Respublikasi Adliya Vazirligi
