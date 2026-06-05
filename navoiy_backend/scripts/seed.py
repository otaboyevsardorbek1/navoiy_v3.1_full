#!/usr/bin/env python3
"""
Navoiy API — Ma'lumotlar bazasini to'ldirish skripti
Barcha 6 ta asar (PDF dan olingan) + 8 ta she'r + 10 ta quiz
"""
import asyncio
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import select
from app.core.config import settings
from app.core.security import hash_password
from app.models.models import (
    User, Asar, Sher, AsarPage, Quiz, AppSetting,  # <-- AppSetting import qo'shildi
    UserRole, AsarCategory, SherType, QuizType
)
from app.services.content_service import ContentService
from app.schemas.schemas import AsarContentJSON, PageContent, QuizInContent
from app.db.database import Base
import json, hashlib

engine = create_async_engine(settings.DATABASE_URL, echo=False)
AsyncSession_ = async_sessionmaker(engine, expire_on_commit=False)

# ─── Asarlar (6 ta — v3.1 bilan bir xil) ──────────────────────────────────────

ASARLAR_DATA = [
    {
        "title": "Hayrat ul-abror", "title_uz": "Hayrat ul-abror",
        "slug": "hayrat-ul-abror", "title_cyrillic": "Ҳайрат ул-аброр",
        "category": AsarCategory.doston, "year": 1483,
        "description": "Xamsa'ning birinchi dostoni — Yaxshilar hayrati. 64 bobdan iborat axloqiy-falsafiy doston.",
        "tags": ["doston", "axloq", "xamsa", "navoiy"],
        "pages": [
            PageContent(
                page_number=1, title="Kirish va tavsif", word_count=200,
                content="""Hayrat ul-abror (Yaxshilar hayrati) — Navoiyning Xamsasidagi birinchi doston, 1483 yilda yozilgan.

Doston 64 bobdan iborat bo'lib, har bir bob alohida axloqiy mavzuni yoritadi. Asarning asosiy g'oyasi: insoniylikning eng oliy namunalarini ko'rsatish, ezgulik va yovuzlik o'rtasidagi kurashni tasvirlash.

Asosiy mavzular:
• Ilm va ma'rifatning qiymati
• Adolat va zulm
• Saxovat va baxillik
• Do'stlik va xiyonat
• Muhabbat va sadoqat
• Kamtarinlik va kibr

"Kim ilm o'rganar, ul inson bo'lur,
Ilmsiz yurgan — inson emas, mol bo'lur." """,
                quizzes=[
                    QuizInContent(id=1, question="Hayrat ul-abror nechta bobdan iborat?",
                        type=QuizType.single, options=["40","50","64","72"],
                        correct_answers=[2], difficulty=2, points=15,
                        explanation="Doston 64 bobdan iborat."),
                    QuizInContent(id=2, question="Doston qaysi yilda yozilgan?",
                        type=QuizType.single, options=["1480","1483","1484","1490"],
                        correct_answers=[1], difficulty=1, points=10,
                        explanation="Doston 1483 yilda yozilgan."),
                ],
            ),
            PageContent(
                page_number=2, title="Axloqiy ta'limotlar", word_count=180,
                content="""Doston 40 maqolatda insoniy fazilatlarni tavsif qiladi. Har bir maqolat hikoya va misralar orqali axloqiy pand-nasihat beradi.

Birinchi maqolat — ilm va aql haqida:
Navoiy ilmni eng buyuk boylik deb hisoblaydi. Ilmsiz kishi yetuk inson bo'la olmaydi.

Ikkinchi maqolat — adolat haqida:
Adolatli podshoh xalqini baxtli qiladi. Zolim esa oxiri halokatga uchraydi.

Uchinchi maqolat — saxovat haqida:
Saxiy odam xalq sevgisini qozonadi. Baxil esa yolg'iz qoladi.""",
                quizzes=[],
            ),
        ],
    },
    {
        "title": "Farhod va Shirin", "title_uz": "Farhod va Shirin",
        "slug": "farhod-va-shirin", "title_cyrillic": "Фарҳод ва Ширин",
        "category": AsarCategory.doston, "year": 1484,
        "description": "Xamsa'ning ikkinchi dostoni — Muhabbat va sadoqat haqidagi buyuk doston.",
        "tags": ["doston", "muhabbat", "xamsa", "navoiy"],
        "pages": [
            PageContent(
                page_number=1, title="Dostonning kirishi", word_count=200,
                content="""Farhod va Shirin — Xamsa tarkibidagi ikkinchi doston. 1484 yilda yozilgan.

Doston ikki sevishganlar — Farhod va Shirin haqida. Farhod — o'z sevgilisi Shirin uchun tog'larni kesuvchi, daryolar qazuvchi qudratli qahramon.

Bosh qahramonlar:
• Farhod — Chin (Xitoy) podshoining o'g'li, me'mor va muhandis
• Shirin — Armaniston malikalari, go'zallik timsoli
• Bahrom — Eron shohi, Farhodning raqibi

Asar muhabbatning ulug'vorligi va insoniy sadoqatning timsolidir.""",
                quizzes=[
                    QuizInContent(id=3, question="Farhod qaysi mamlakatning shahzodasi?",
                        type=QuizType.single, options=["Armaniston","Eron","Chin","Rum"],
                        correct_answers=[2], difficulty=2, points=15,
                        explanation="Farhod Chin (Xitoy) podshoining o'g'li."),
                    QuizInContent(id=4, question="Farhod qaysi kasbi orqali xalq uchun xizmat qiladi?",
                        type=QuizType.single,
                        options=["Shoir","Me'mor va muhandis","Savdogar","Dehqon"],
                        correct_answers=[1], difficulty=2, points=15,
                        explanation="Farhod me'mor va muhandis sifatida tog'larni kesib, ariq qazib beradi."),
                ],
            ),
            PageContent(
                page_number=2, title="Syujet va voqealar", word_count=220,
                content="""Farhod Armanistonga safar qilib, malika Shirinning suratini ko'radi va unga oshiq bo'ladi. Shirin ham Farhodga ko'ngil qo'yadi.

Bahrom shoh ham Shirinni sevadi va Farhodga raqib sifatida chiqadi. U Farhodga qattiq shart qo'yadi: tog'dan tosh kesib ariq qazib bersa, Shirinni beradi.

Farhod bu ishni bir zumda bajardi. Bahrom esa hiyla ishlatib, Shirinning o'ldi degan yolg'on xabar yuboradi.

Farhod bu dardga chiday olmay, hayotdan ko'z yumadi. Shirin ham sevgilisiz yashay olmay, uning qabrida jon beradi.""",
                quizzes=[],
            ),
        ],
    },
    {
        "title": "Layli va Majnun", "title_uz": "Layli va Majnun",
        "slug": "layli-va-majnun", "title_cyrillic": "Лайли ва Мажнун",
        "category": AsarCategory.doston, "year": 1484,
        "description": "Xamsa'ning uchinchi dostoni — Ishq va iztirob haqidagi sehrli doston.",
        "tags": ["doston", "ishq", "xamsa", "navoiy"],
        "pages": [
            PageContent(
                page_number=1, title="Dostonning kirishi", word_count=190,
                content="""Layli va Majnun — Xamsa tarkibidagi uchinchi doston. 1484 yilda yozilgan.

Qays ismli yigit Layliga oshiq bo'ladi va uning muhabbati uni "Majnun"ga aylantiradi.

Bosh qahramonlar:
• Qays (Majnun) — asil va bag'ri keng yigit, ishqdan devona
• Layli — go'zal qiz, Majnunning sevgilisi
• Ibn Salom — Layli turmushga chiqqan boy

Doston voqealari Arab cho'llarida sodir bo'ladi.""",
                quizzes=[
                    QuizInContent(id=5, question="Majnunning haqiqiy ismi nima?",
                        type=QuizType.single, options=["Farhod","Qays","Bahrom","Iskandar"],
                        correct_answers=[1], difficulty=1, points=10,
                        explanation="Majnunning haqiqiy ismi Qays. Ishqdan devona bo'lgani uchun Majnun (telba) deb atashgan."),
                ],
            ),
            PageContent(
                page_number=2, title="Syujet", word_count=200,
                content="""Qays Layli bilan bir maktabda o'qib, unga oshiq bo'ladi. Layli ham uni sevadi.

Layli otasi uni Qaysga bermaydi va Ibn Solomga uzatadi. Qays bu dardga chiday olmay, cho'llarga ketib, hayvonat bilan yashay boshlaydi.

Layli ham xursand emas, doim Majnunni o'ylaydi. Ibn Salom o'lgandan so'ng, Layli va Majnun uchrashadi, lekin ko'p o'tmay ikkalasi ham vafot etadi.

Ular bir qabristonda yonma-yon dafn qilinadi.""",
                quizzes=[],
            ),
        ],
    },
    {
        "title": "Sab'ai sayyor", "title_uz": "Sab'ai sayyor",
        "slug": "sabai-sayyor", "title_cyrillic": "Сабъаи сайёр",
        "category": AsarCategory.doston, "year": 1484,
        "description": "Xamsa'ning to'rtinchi dostoni — Etti sayyora haqida.",
        "tags": ["doston", "falsafa", "xamsa", "navoiy"],
        "pages": [
            PageContent(
                page_number=1, title="Dostonning kirishi", word_count=180,
                content="""Sab'ai sayyor (Etti sayyora) — Xamsa tarkibidagi to'rtinchi doston. 1484 yilda yozilgan.

Doston Bahrom Gur podshoh haqida bo'lib, u etti sayyoraga nisbat berilgan etti saroyu etti malikasi bilan o'tkazgan kunlari hikoya qilinadi.

Har bir bob bir sayyora va unga mos rang, kun bilan bog'liq hikoyani o'z ichiga oladi:
• Shanba — Zuhal (Saturn) — qora saroy
• Yakshanba — Quyosh — sariq saroy
• Dushanba — Oy — yashil saroy""",
                quizzes=[
                    QuizInContent(id=6, question="'Sab'ai sayyor' so'zi nima ma'noni anglatadi?",
                        type=QuizType.single,
                        options=["Etti qirol","Etti sayyora","Etti dengiz","Etti tog'"],
                        correct_answers=[1], difficulty=1, points=10,
                        explanation="Sab'ai sayyor arabcha 'etti sayyora' degan ma'noni bildiradi."),
                ],
            ),
        ],
    },
    {
        "title": "Saddi Iskandariy", "title_uz": "Saddi Iskandariy",
        "slug": "saddi-iskandariy", "title_cyrillic": "Садди Искандарий",
        "category": AsarCategory.doston, "year": 1485,
        "description": "Xamsa'ning beshinchi dostoni — Iskandar to'sig'i. Tarixiy-falsafiy doston.",
        "tags": ["doston", "tarix", "xamsa", "navoiy"],
        "pages": [
            PageContent(
                page_number=1, title="Dostonning kirishi", word_count=200,
                content="""Saddi Iskandariy (Iskandar to'sig'i) — Xamsa tarkibidagi beshinchi va oxirgi doston. 1485 yilda yozilgan.

Doston Makedoniyalik Aleksandr (Iskandar) hayoti va yurishlariga bag'ishlangan.

Asarning o'ziga xos xususiyatlari:
• Tarixiy shaxs — Iskandar Zulqarnayn
• Falsafiy g'oyalar — adolatli podshoh obrazi
• Geografik ma'lumotlar — yurishlar yo'llari
• Yog'uj-Maguj to'sig'i — doston nomi shu voqeadan olingan

Doston geografiya va tarix fanlari bilan chambarchas bog'liq.""",
                quizzes=[
                    QuizInContent(id=7, question="'Saddi Iskandariy' asarida qaysi tarixiy shaxs tasvirlangan?",
                        type=QuizType.single,
                        options=["Amir Temur","Iskandar (Aleksandr)","Chingizxon","Doro"],
                        correct_answers=[1], difficulty=1, points=10,
                        explanation="Doston Makedoniyalik Aleksandr (Iskandar) haqida."),
                ],
            ),
        ],
    },
    {
        "title": "Badoiy ul-vasat", "title_uz": "Badoiy ul-vasat",
        "slug": "badoiy-ul-vasat", "title_cyrillic": "Бадоеъ ул-васат",
        "category": AsarCategory.boshqa, "year": 1498,
        "description": "Xazoyin ul-maoniy devonining ikkinchi qismi — o'rta yosh g'azallari.",
        "tags": ["devon", "gazal", "lirika", "navoiy"],
        "pages": [
            PageContent(
                page_number=1, title="Devon haqida", word_count=170,
                content="""Badoiy ul-vasat (O'rta yamoniyatlar) — Navoiyning "Xazoyin ul-maoniy" (Ma'nolar xazinasi) devonining ikkinchi qismi.

Devon 1498 yilda tartib berilgan bo'lib, Navoiyning o'rta yoshdagi she'rlarini o'z ichiga oladi.

Devon tarkibi:
• G'azallar — asosiy janr
• Ruboiylar — to'rt misrali she'rlar
• Qit'alar — parchalar
• Tuyuqlar — o'zbek she'riyatiga xos janr

Devon Alif harfidan boshlab tartiblanib, barcha harflarga she'rlar yozilgan.""",
                quizzes=[
                    QuizInContent(id=8, question="'Xazoyin ul-maoniy' so'zi nima ma'noni anglatadi?",
                        type=QuizType.single,
                        options=["Bahor xazinasi","Ma'nolar xazinasi","Oltin xazina","Bilim xazinasi"],
                        correct_answers=[1], difficulty=2, points=15,
                        explanation="Xazoyin ul-maoniy arabcha 'Ma'nolar xazinasi' degan ma'noni bildiradi."),
                ],
            ),
        ],
    },
]

SHERLAR_DATA = [
    {"title":"Ko'ngul mulki","slug":"kongul-mulki","type":SherType.gazal,
     "content":"Ko'ngul mulkida sulton bo'lsa ishq,\nNechuk ta'rif etsam, ne bo'lsa farq?\nKo'z — dengizi ul mulkning, ko'ngl — bar,\nKo'rib bo'lmas ul daryoni zevar.\n\nNavoiy, ko'nglungda ishq bo'lmasa,\nHayot ne kerak, umr bo'lmasa?",
     "description":"Ko'ngul va ishq haqida g'azal","like_count":145},
    {"title":"Ilm madhi","slug":"ilm-madhi","type":SherType.ruboiy,
     "content":"Ilm ahlini aziz tutkim, ilm aziz,\nIlmsiz kishini bilgil sen kamsiz.\nKim ilm o'rganar, ul inson bo'lur,\nIlmsiz yurgan — inson emas, mol bo'lur.",
     "description":"Ilm va ma'rifat haqida ruboiy","like_count":289},
    {"title":"Vatan sevgisi","slug":"vatan-sevgisi","type":SherType.qita,
     "content":"Vatandir kishiga jannatdan aziz,\nVatansiz yashagan har dam bo'lur qiz.\nKo'z yoshlar to'kar vatandin uzoq,\nKim ko'rmas yana o'lkasini, yurtini.",
     "description":"Vatan sevgisini ulug'lovchi she'r","like_count":312},
    {"title":"Bahor fasli","slug":"bahor-fasli","type":SherType.gazal,
     "content":"Bahor fasli kelib gul yuzin ochdi,\nBulbul nag'masi bog'larni to'ldi.\nHar yon lola va rayhon isi tarar,\nKo'ngullar shodlig'i cheksiz qo'yar.",
     "description":"Bahor go'zalligiga bag'ishlangan she'r","like_count":198},
    {"title":"Hikmat: Kishi qadri","slug":"hikmat-kishi-qadri","type":SherType.hikmat,
     "content":"Kishi qadrin bilur eding bir kun,\nAmmo ketsa, bilinur qadr tamom.\nBorida qadrin bil, ketmasin deb,\nYo'qolsa, armoni qolur behad.",
     "description":"Inson qadri haqida hikmat","like_count":421},
    {"title":"Do'stlik haqida","slug":"dostlik-haqida","type":SherType.ruboiy,
     "content":"Do'st ul erur kim, qilgay dard qo'shib,\nYolg'iz qo'ymas, bir umr yonib.\nYovuz kunda bilinar do'st va dushman,\nDo'stlik — oltindek sinashdan o'tib.",
     "description":"Haqiqiy do'stlik haqida","like_count":178},
    {"title":"Xub el bila","slug":"xub-el-bila","type":SherType.qita,
     "content":"Xub el bila suhbat tutubon xub o'lg'il,\nYaxshini talab qilg'il-u matlub o'lg'il.\nShirin so'z ila xalqqa marg'ub o'lg'il,\nYumshoq de hadisingni-yu, mahbub o'lg'il.",
     "description":"Yaxshilik va so'z madhi","like_count":256},
    {"title":"Adolat haqida","slug":"adolat-haqida","type":SherType.hikmat,
     "content":"Adolat ila bo'l agar sulton bo'lsang,\nZulm ila taxt ustida o'ltirsang ham.\nEl ko'ngli mulkini zabt etmak uchun,\nBir mard bo'l, bir odil bo'l, bir inson bo'l.",
     "description":"Adolat va podshohlik haqida hikmat","like_count":334},
]


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("✅ DB jadvallar tayyor")

    async with AsyncSession_() as db:
        # ─── Admin va user yaratish ────────────────────────────────────────
        for udata in [
            {"username":"admin","email":"admin@navoiy.uz","full_name":"Administrator",
             "password":"admin123","role":UserRole.admin},
            {"username":"user","email":"user@navoiy.uz","full_name":"Test foydalanuvchi",
             "password":"user123","role":UserRole.user},
        ]:
            ex = await db.execute(select(User).where(User.username == udata["username"]))
            if not ex.scalar_one_or_none():
                db.add(User(
                    username=udata["username"], email=udata["email"],
                    full_name=udata["full_name"],
                    hashed_password=hash_password(udata["password"]),
                    role=udata["role"], is_active=True,
                ))
        await db.commit()
        print("✅ Foydalanuvchilar: admin/admin123 | user/user123")

        # ─── App Settings (Telegram Bot uchun) ─────────────────────────────
        print("⚙️  App Settings yaratilmoqda...")
        
        settings_data = [
            {"key": "bot_token", "value": ""},  # Admin panelda to'ldiriladi
            {"key": "chat_id", "value": ""},    # Admin panelda to'ldiriladi
        ]

        for s in settings_data:
            ex = await db.execute(select(AppSetting).where(AppSetting.key == s["key"]))
            if not ex.scalar_one_or_none():
                db.add(AppSetting(key=s["key"], value=s["value"]))
        
        await db.commit()
        print("✅ Sozlamalar jadvali tayyor.")

        # ─── Asarlar ──────────────────────────────────────────────────────
        cs = ContentService()
        for meta in ASARLAR_DATA:
            pages = meta.pop("pages")

            ex = await db.execute(select(Asar).where(Asar.slug == meta["slug"]))
            if ex.scalar_one_or_none():
                print(f"  ⏭  {meta['slug']} mavjud")
                meta["pages"] = pages
                continue

            asar = Asar(
                title=meta["title"], title_uz=meta["title_uz"],
                slug=meta["slug"], description=meta["description"],
                category=meta["category"], year=meta["year"],
                language="uz_cyrillic", tags=meta["tags"],
            )
            db.add(asar)
            await db.flush()

            # JSON content yaratish
            content_obj = AsarContentJSON(
                asar_id=asar.id, slug=asar.slug, title=asar.title_uz, # type: ignore
                version=1, checksum="", total_pages=len(pages), language="uz_cyrillic",
                pages=pages,
            )
            json_str = content_obj.model_dump_json(indent=2)
            checksum = hashlib.sha256(json_str.encode()).hexdigest()
            content_obj.checksum = checksum

            checksum_out, file_size = await cs.save_asar_content(asar.slug, content_obj) # type: ignore
            asar.content_file = f"content/asarlar/{asar.slug}.json" # type: ignore
            asar.total_pages = len(pages) # type: ignore
            asar.checksum = checksum_out # type: ignore

            for pg in pages:
                db.add(AsarPage(
                    asar_id=asar.id, page_number=pg.page_number,
                    title=pg.title, word_count=pg.word_count,
                    has_quiz=len(pg.quizzes) > 0,
                ))

            await db.commit()
            print(f"  ✅ {asar.title_uz} ({len(pages)} sahifa)")

        # ─── She'rlar ──────────────────────────────────────────────────────
        for sd in SHERLAR_DATA:
            ex = await db.execute(select(Sher).where(Sher.slug == sd["slug"]))
            if not ex.scalar_one_or_none():
                db.add(Sher(
                    title=sd["title"], slug=sd["slug"],
                    content=sd["content"], type=sd["type"],
                    description=sd["description"], like_count=sd["like_count"],
                ))
        await db.commit()
        print(f"  ✅ {len(SHERLAR_DATA)} ta she'r qo'shildi")

    print("\n🎉 Seed muvaffaqiyatli yakunlandi!")
    print("   admin / admin123")
    print("   user  / user123")
    print("   API: http://localhost:8000/docs")


if __name__ == "__main__":
    asyncio.run(seed())