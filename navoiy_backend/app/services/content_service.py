# app/services/content_service.py
import os
import json
import hashlib
import aiofiles
from pathlib import Path
from typing import Optional, Tuple
from ..core.config import settings
from ..schemas.schemas import AsarContentJSON, PageContent, QuizInContent


class ContentService:
    """JSON content fayllari bilan ishlash."""

    def __init__(self):
        self.content_dir = Path(settings.CONTENT_DIR)
        self.asarlar_dir = self.content_dir / "asarlar"
        self.sherlar_dir = self.content_dir / "sherlar"
        self._ensure_dirs()

    def _ensure_dirs(self):
        self.asarlar_dir.mkdir(parents=True, exist_ok=True)
        self.sherlar_dir.mkdir(parents=True, exist_ok=True)

    def _asar_path(self, slug: str) -> Path:
        return self.asarlar_dir / f"{slug}.json"

    def _sher_path(self, slug: str) -> Path:
        return self.sherlar_dir / f"{slug}.json"

    def compute_checksum(self, content: str) -> str:
        return hashlib.sha256(content.encode()).hexdigest()

    def get_file_size(self, path: Path) -> int:
        return path.stat().st_size if path.exists() else 0

    # ─── Async read/write ─────────────────────────────────────────────────────

    async def save_asar_content(self, slug: str, content: AsarContentJSON) -> Tuple[str, int]:
        """JSON faylga saqlaydi. (checksum, file_size) qaytaradi."""
        path = self._asar_path(slug)
        json_str = content.model_dump_json(indent=2)
        checksum = self.compute_checksum(json_str)
        async with aiofiles.open(path, "w", encoding="utf-8") as f:
            await f.write(json_str)
        return checksum, path.stat().st_size

    async def read_asar_content(self, slug: str) -> Optional[dict]:
        path = self._asar_path(slug)
        if not path.exists():
            return None
        async with aiofiles.open(path, "r", encoding="utf-8") as f:
            raw = await f.read()
        return json.loads(raw)

    async def read_asar_page(self, slug: str, page_number: int) -> Optional[dict]:
        """Faqat kerakli sahifani qaytaradi — butun faylni o'qimaydi."""
        content = await self.read_asar_content(slug)
        if not content:
            return None
        pages = content.get("pages", [])
        for page in pages:
            if page.get("page_number") == page_number:
                return page
        return None

    async def delete_asar_content(self, slug: str) -> bool:
        path = self._asar_path(slug)
        if path.exists():
            path.unlink()
            return True
        return False

    async def asar_content_exists(self, slug: str) -> bool:
        return self._asar_path(slug).exists()

    async def get_asar_checksum(self, slug: str) -> Optional[str]:
        path = self._asar_path(slug)
        if not path.exists():
            return None
        async with aiofiles.open(path, "r", encoding="utf-8") as f:
            raw = await f.read()
        return self.compute_checksum(raw)

    async def get_asar_file_size(self, slug: str) -> int:
        return self.get_file_size(self._asar_path(slug))

    def create_sample_asar_content(
        self, asar_id: int, slug: str, title: str, version: int = 1
    ) -> AsarContentJSON:
        """Demo ma'lumot yaratish uchun."""
        pages = [
            PageContent(
                page_number=1,
                title="Kirish",
                content=f"{title} asarining birinchi sahifasi.\n\nBu yerda asarning kirish qismi joylashadi.",
                word_count=20,
                quizzes=[
                    QuizInContent(
                        id=1,
                        question=f"'{title}' asari qachon yozilgan?",
                        type="single", # type: ignore
                        options=["1483-yil", "1494-yil", "1501-yil", "1510-yil"],
                        correct_answers=[0],
                        explanation="Asar XV asrda Alisher Navoiy tomonidan yozilgan.",
                        difficulty=1,
                        points=10,
                    )
                ],
            ),
            PageContent(
                page_number=2,
                title="Asosiy qism",
                content=f"{title} asarining ikkinchi sahifasi.\n\nBu yerda asarning asosiy mazmuni keltirilgan.",
                word_count=30,
                quizzes=[],
            ),
        ]
        content_str = json.dumps({"pages": [p.model_dump() for p in pages]}, ensure_ascii=False)
        checksum = self.compute_checksum(content_str)
        return AsarContentJSON(
            asar_id=asar_id,
            slug=slug,
            title=title,
            version=version,
            checksum=checksum,
            total_pages=len(pages),
            language="uz",
            pages=pages,
        )


content_service = ContentService()
