# Android Studio Loyiha Tahlilchisi

**Versiya:** 1.0.0

Android Studio loyihalarini tahlil qiluvchi professional Python dasturi. JSON, ZIP va papka manbalarini qayta ishlaydi, modullar, resurslar, build.gradle va manifest fayllarini tahlil qiladi. Bir nechta formatlarda (TXT, CSV, JSON, HTML, Markdown) hisobot chiqaradi.

## Xususiyatlar

- **Bir nechta manba turlari:** JSON fayllar, ZIP arxivlar, Android loyiha papkalari
- **Filtrlash:** Fayl kengaytmalari, papka nomlari, regex asosida
- **Modul tahlili:** build.gradle, AndroidManifest.xml, dependencies
- **Resurslar tahlili:** Layout, strings, drawable
- **Kod sifati tekshiruvi:** Bo'sh catch bloklari, deprecated metodlar
- **Bir nechta chiqish formatlari:** TXT, CSV, JSON, HTML (interaktiv), Markdown
- **Grafik interfeys (GUI):** Tkinter asosida
- **Parallel ishlash:** Ko'p yadroli protsessorlarni qo'llab-quvvatlash
- **Keshlash:** Qayta tahlilni tezlashtirish
- **Integratsiyalar:** Git, Jira, Telegram/Slack xabarlar
- **Avtomatik backup:** ZIP arxivga saqlash

## O'rnatish

### Talablar

- Python 3.9+
- pip

### Tashqi kutubxonalar (ixtiyoriy)

```bash
# Katta JSON fayllar uchun streaming
pip install ijson

# Rasm o'lchamlari uchun
pip install Pillow

# Excel eksport uchun
pip install openpyxl

# Progress bar
pip install tqdm

# Konfiguratsiya fayllari
pip install pyyaml

# API aloqalari (Telegram, Jira)
pip install requests

# Telegram bot
pip install python-telegram-bot
```

### Dasturni o'rnatish

1. Repozitoriyni klonlash:
```bash
git clone https://github.com/username/android-extractor.git
cd android-extractor
```

2. Konfiguratsiya faylini yaratish (ixtiyoriy):
```bash
python android_extractor.py --create-config
```

## Foydalanish

### GUI rejimi

```bash
python android_extractor.py
```

### Buyruq satri rejimi

#### Asosiy tahlil

```bash
# JSON fayldan tahlil
python android_extractor.py --source project_structure.json

# Papkani tahlil qilish
python android_extractor.py --source /path/to/android/project

# ZIP arxivni tahlil qilish
python android_extractor.py --source project.zip
```

#### Filtrlash

```bash
# Faqat Java va Kotlin fayllar
python android_extractor.py --source ./project --extensions .java,.kt

# Faqat "app" papkasi
python android_extractor.py --source ./project --filter-folder app

# Regex bilan filtrlash
python android_extractor.py --source ./project --regex "MainActivity.*\.java"
```

#### Chiqish formatlari

```bash
# Faqat TXT
python android_extractor.py --source ./project --output-format txt

# CSV va HTML
python android_extractor.py --source ./project --output-format csv,html

# Barcha formatlar
python android_extractor.py --source ./project --output-format txt,csv,json,html,md
```

#### Tahlil opsiyalari

```bash
# Faqat statistika
python android_extractor.py --source ./project --stats-only

# Modul tahlilisiz
python android_extractor.py --source ./project --no-modules

# Parallel ishlashni o'chirish
python android_extractor.py --source ./project --no-parallel

# Keshni ishlatmaslik
python android_extractor.py --source ./project --no-cache
```

#### Git integratsiyasi

```bash
# Tahlil tugagandan so'ng avtomatik commit
python android_extractor.py --source ./project --git-commit
```

#### Log darajasi

```bash
# Debug log
python android_extractor.py --source ./project --log-level DEBUG
```

## Konfiguratsiya

`config.json` fayli orqali dasturni sozlash:

```json
{
  "filters": {
    "extensions": [".java", ".kt", ".xml", ".gradle"],
    "exclude_patterns": ["build/", ".gradle/", ".idea/"]
  },
  "output": {
    "directory": "output",
    "formats": ["txt", "json", "html"],
    "auto_backup": true
  },
  "analysis": {
    "parallel": true,
    "max_workers": 4,
    "use_cache": true
  },
  "logging": {
    "level": "INFO",
    "file": "android_extractor.log"
  },
  "notifications": {
    "email": {
      "enabled": false,
      "smtp_host": "smtp.gmail.com",
      "smtp_port": 587,
      "username": "your-email@gmail.com",
      "password": "your-password",
      "to_addrs": ["recipient@example.com"]
    },
    "telegram": {
      "enabled": false,
      "bot_token": "YOUR_BOT_TOKEN",
      "chat_id": "YOUR_CHAT_ID"
    }
  }
}
```

## Hisobot formatlari

### TXT

Oddiy matnli hisobot. Barcha statistikalar, modullar va resurslar haqida ma'lumot.

### CSV

Jadval ma'lumotlari. Har bir fayl uchun qator: yo'li, kengaytmasi, o'lchami, LOC, modul nomi.

### JSON

Mashina o'qiy oladigan format. Barcha tahlil ma'lumotlari JSON strukturada.

### HTML

Interaktiv veb-hisobot:
- Qidiruv va filtrlash
- Tablitsalar va diagrammalar
- Modul tahlili
- Responsive dizayn

### Markdown

GitHub README yoki dokumentatsiya uchun.

## Modul tahlili

Dastur quyidagi modul ma'lumotlarini tahlil qiladi:

- **build.gradle:**
  - applicationId
  - compileSdk, minSdk, targetSdk
  - versionCode, versionName
  - Dependencies (implementation, api, compileOnly)
  - ProGuard sozlamalari

- **AndroidManifest.xml:**
  - package name
  - Permissions
  - Activities, Services, Receivers
  - Intent-filters

## Resurslar tahlili

- **Layout:** View ID va string matnlari
- **Strings:** Barcha string resurslari
- **Drawables:** Fayllar va o'lchamlar
- **Takrorlangan resurslar:** Topish va hisobot qilish

## Kod sifati tekshiruvi

- Bo'sh catch bloklari
- Deprecated metodlar
- Import qilinmagan resurslar
- TODO kommentariyalar

## Log tizimi

Barcha amallar `android_extractor.log` fayliga yoziladi:
- Vaqt tamg'asi
- Log darajasi (DEBUG, INFO, WARNING, ERROR)
- Xabar matni
- Xatoliklar tracback bilan

## Xavfsizlik

- Email parollari konfiguratsiya faylida saqlanadi
- Git repozitoriyga qo'shmang!
- `.gitignore` fayliga qo'shing:
  ```
  config.json
  android_extractor.log
  .cache/
  ```

## Muammolarni hal qilish

### JSON fayl ochilmayapti

Katta JSON fayllar uchun `ijson` kutubxonasini o'rnating:
```bash
pip install ijson
```

### ZIP arxiv ochilmayapti

ZIP fayl buzilgan yoki xavfsiz emas. Boshqa arxiv menejeri bilan tekshiring.

### Xotira yetishmayapti

Katta loyihalar uchun:
```bash
python android_extractor.py --source ./project --no-parallel
```

### GUI ishlamayapti

Tkinter o'rnatilganini tekshiring:
```bash
python -m tkinter
```

## Rivojlanish

### Yangi funksiyalar

- [ ] Excel (.xlsx) eksport
- [ ] PDF hisobot
- [ ] Diagrammalar va grafiklar
- [ ] CI/CD integratsiyasi
- [ ] Docker qo'llab-quvvatlash

### Xatoliklar

Xatoliklar haqida xabar bering: [GitHub Issues](https://github.com/username/android-extractor/issues)

## Litsenziya

MIT License

## Mualliflar

- Android Extractor Team

## Minnatdorchilik

- [ijson](https://github.com/ICRAR/ijson) - Katta JSON streaming
- [openpyxl](https://openpyxl.readthedocs.io/) - Excel fayllar
- [Pillow](https://python-pillow.org/) - Rasm ishlov berish
