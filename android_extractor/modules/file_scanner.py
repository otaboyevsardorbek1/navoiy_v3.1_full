"""
Android Studio Loyiha Tahlilchisi - Fayl skanerlash moduli
"""
import os
import json
import zipfile
import re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import defaultdict


class FileScanner:
    """Android loyiha fayllarini skanerlash"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger
        self.extensions = config_manager.get('filters.extensions', [])
        self.exclude_patterns = config_manager.get('filters.exclude_patterns', [])
        self.max_workers = config_manager.get('analysis.max_workers', 4)

    def scan_source(self, source_path):
        """Manbani skanerlash (JSON, ZIP, yoki papka)"""
        self.logger.info(f"Manba skanerlanmoqda: {source_path}")

        if not os.path.exists(source_path):
            raise FileNotFoundError(f"Manba topilmadi: {source_path}")

        # JSON fayl
        if source_path.endswith('.json'):
            return self._scan_json(source_path)

        # ZIP arxiv
        if source_path.endswith('.zip'):
            return self._scan_zip(source_path)

        # Papka
        if os.path.isdir(source_path):
            return self._scan_directory(source_path)

        raise ValueError(f"Qo'llab-quvvatlanmaydigan manba turi: {source_path}")

    def _scan_json(self, json_path):
        """JSON faylni skanerlash"""
        self.logger.info(f"JSON fayl o'qilmoqda: {json_path}")

        try:
            # Katta fayllar uchun ijson ishlatish
            try:
                import ijson
                files = []
                with open(json_path, 'rb') as f:
                    for prefix, event, value in ijson.parse(f):
                        if event == 'string' and 'path' in prefix:
                            files.append({'path': value})
                return files
            except ImportError:
                self.logger.warning("ijson o'rnatilmagan. Standart json ishlatiladi.")
                with open(json_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if isinstance(data, dict) and 'structure' in data:
                        return self._extract_from_structure(data['structure'])
                    return self._extract_from_structure(data)
        except Exception as e:
            self.logger.error(f"JSON o'qishda xato: {e}")
            raise

    def _extract_from_structure(self, structure, base_path=""):
        """Strukturadan fayllarni ajratib olish"""
        files = []

        if isinstance(structure, dict):
            for key, value in structure.items():
                current_path = os.path.join(base_path, key)
                if isinstance(value, str):
                    files.append({
                        'path': current_path,
                        'content': value
                    })
                else:
                    files.extend(self._extract_from_structure(value, current_path))

        elif isinstance(structure, list):
            for item in structure:
                files.extend(self._extract_from_structure(item, base_path))

        return files

    def _scan_zip(self, zip_path):
        """ZIP arxivni skanerlash"""
        self.logger.info(f"ZIP arxiv ochilmoqda: {zip_path}")

        files = []
        temp_dir = os.path.join(os.path.dirname(zip_path), ".temp_extract")
        os.makedirs(temp_dir, exist_ok=True)

        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(temp_dir)

            # Vaqtinchalik papkani skanerlash
            files = self._scan_directory(temp_dir)

            # Vaqtinchalik fayllarni tozalash
            import shutil
            shutil.rmtree(temp_dir, ignore_errors=True)

            return files
        except Exception as e:
            self.logger.error(f"ZIP ochishda xato: {e}")
            raise

    def _scan_directory(self, dir_path):
        """Papkani skanerlash"""
        self.logger.info(f"Papka skanerlanmoqda: {dir_path}")

        files = []

        for root, dirs, filenames in os.walk(dir_path):
            # Exclude patternlarni tekshirish
            dirs[:] = [d for d in dirs if not self._should_exclude(os.path.join(root, d))]

            for filename in filenames:
                file_path = os.path.join(root, filename)

                if self._should_exclude(file_path):
                    continue

                # Kengaytmalar bo'yicha filtrlash
                if self.extensions:
                    ext = os.path.splitext(filename)[1].lower()
                    if ext not in self.extensions:
                        continue

                try:
                    stat = os.stat(file_path)
                    files.append({
                        'path': file_path,
                        'relative_path': os.path.relpath(file_path, dir_path),
                        'size': stat.st_size,
                        'modified': stat.st_mtime
                    })
                except Exception as e:
                    self.logger.warning(f"Faylni o'qishda xato: {file_path} - {e}")

        self.logger.info(f"Jami {len(files)} ta fayl topildi")
        return files

    def _should_exclude(self, path):
        """Yo'lni exclude patternlari bo'yicha tekshirish"""
        path_str = str(path).replace('\\\\', '/')

        for pattern in self.exclude_patterns:
            if pattern in path_str:
                return True
            # Regex tekshiruvi
            try:
                if re.search(pattern, path_str):
                    return True
            except re.error:
                pass

        return False

    def filter_by_folder(self, files, folder_name):
        """Papka nomi bo'yicha filtrlash"""
        if not folder_name:
            return files

        filtered = []
        for file_info in files:
            path = file_info.get('path', '')
            if folder_name in path:
                filtered.append(file_info)

        self.logger.info(f"Filtrlangan: {len(filtered)} / {len(files)} ta fayl")
        return filtered

    def filter_by_regex(self, files, pattern):
        """Regex bo'yicha filtrlash"""
        if not pattern:
            return files

        try:
            regex = re.compile(pattern)
            filtered = [f for f in files if regex.search(f.get('path', ''))]
            self.logger.info(f"Regex filtrlangan: {len(filtered)} / {len(files)} ta fayl")
            return filtered
        except re.error as e:
            self.logger.error(f"Regex xato: {e}")
            return files
