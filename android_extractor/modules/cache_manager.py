"""
Android Studio Loyiha Tahlilchisi - Kesh boshqaruvi moduli
"""
import os
import json
import pickle
import hashlib
from datetime import datetime, timedelta


class CacheManager:
    """Natijalarni keshlash va qayta ishlatish"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger
        self.cache_dir = config_manager.get('analysis.cache_directory', '.cache')
        self.enabled = config_manager.get('analysis.use_cache', True)

        if self.enabled:
            os.makedirs(self.cache_dir, exist_ok=True)

    def _get_cache_key(self, source_path, options=None):
        """Kesh kalitini yaratish"""
        key_data = source_path
        if options:
            key_data += json.dumps(options, sort_keys=True)

        return hashlib.md5(key_data.encode()).hexdigest()

    def _get_cache_path(self, cache_key):
        """Kesh fayli yo'lini olish"""
        return os.path.join(self.cache_dir, f"{cache_key}.pkl")

    def get_cached_result(self, source_path, options=None):
        """Keshlangan natijani olish"""
        if not self.enabled:
            return None

        cache_key = self._get_cache_key(source_path, options)
        cache_path = self._get_cache_path(cache_key)

        if not os.path.exists(cache_path):
            return None

        try:
            # Fayl yoshini tekshirish (7 kun)
            file_age = datetime.now() - datetime.fromtimestamp(os.path.getmtime(cache_path))
            if file_age > timedelta(days=7):
                self.logger.info("Kesh eskirgan, qayta tahlil qilinadi")
                os.remove(cache_path)
                return None

            with open(cache_path, 'rb') as f:
                result = pickle.load(f)

            self.logger.info("Keshdan natija yuklandi")
            return result

        except Exception as e:
            self.logger.warning(f"Keshni o'qishda xato: {e}")
            return None

    def save_result(self, source_path, result, options=None):
        """Natijani keshga saqlash"""
        if not self.enabled:
            return False

        cache_key = self._get_cache_key(source_path, options)
        cache_path = self._get_cache_path(cache_key)

        try:
            with open(cache_path, 'wb') as f:
                pickle.dump(result, f)

            self.logger.info("Natija keshga saqlandi")
            return True

        except Exception as e:
            self.logger.warning(f"Keshga saqlashda xato: {e}")
            return False

    def clear_cache(self):
        """Keshni tozalash"""
        if not os.path.exists(self.cache_dir):
            return

        try:
            for filename in os.listdir(self.cache_dir):
                if filename.endswith('.pkl'):
                    os.remove(os.path.join(self.cache_dir, filename))

            self.logger.info("Kesh tozalandi")

        except Exception as e:
            self.logger.error(f"Keshni tozalashda xato: {e}")

    def get_cache_info(self):
        """Kesh haqida ma'lumot"""
        if not os.path.exists(self.cache_dir):
            return {"files": 0, "size": 0}

        files = [f for f in os.listdir(self.cache_dir) if f.endswith('.pkl')]
        total_size = sum(os.path.getsize(os.path.join(self.cache_dir, f)) for f in files)

        return {
            "files": len(files),
            "size": self._format_size(total_size)
        }

    def _format_size(self, size_bytes):
        """Hajmni formatlash"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"
