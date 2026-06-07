"""
Android Studio Loyiha Tahlilchisi - Konfiguratsiya moduli
"""
import os
import json
from pathlib import Path

DEFAULT_CONFIG = {
    "filters": {
        "extensions": [
            ".java", ".kt", ".xml", ".gradle", ".properties", ".pro",
            ".aidl", ".gitignore", ".md", ".gradle.kts", ".iml"
        ],
        "folders": [],
        "exclude_patterns": [
            "build/", ".gradle/", ".idea/", "*.tmp", "*.log",
            "node_modules/", ".git/"
        ]
    },
    "output": {
        "directory": "output",
        "formats": ["txt", "json", "html"],
        "auto_backup": True
    },
    "analysis": {
        "parallel": True,
        "max_workers": 4,
        "use_cache": True,
        "cache_directory": ".cache"
    },
    "logging": {
        "level": "INFO",
        "file": "android_extractor.log",
        "max_size_mb": 10,
        "backup_count": 5
    },
    "notifications": {
        "email": {
            "enabled": False,
            "smtp_host": "",
            "smtp_port": 587,
            "username": "",
            "password": "",
            "from_addr": "",
            "to_addrs": []
        },
        "telegram": {
            "enabled": False,
            "bot_token": "",
            "chat_id": ""
        }
    },
    "integrations": {
        "git": {
            "auto_commit": False,
            "commit_message": "Android Extractor: Hisobot yangilandi"
        },
        "jira": {
            "enabled": False,
            "url": "",
            "username": "",
            "api_token": "",
            "project_key": ""
        }
    }
}


class ConfigManager:
    """Konfiguratsiyani boshqarish"""

    def __init__(self, config_path="config.json"):
        self.config_path = config_path
        self.config = self.load_config()

    def load_config(self):
        """Konfiguratsiyani yuklash"""
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r', encoding='utf-8') as f:
                    loaded = json.load(f)
                    # Default bilan birlashtirish
                    merged = self._merge_dicts(DEFAULT_CONFIG.copy(), loaded)
                    return merged
            except Exception as e:
                print(f"Konfiguratsiyani yuklashda xato: {e}. Standart ishlatiladi.")
                return DEFAULT_CONFIG.copy()
        return DEFAULT_CONFIG.copy()

    def save_config(self):
        """Konfiguratsiyani saqlash"""
        try:
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"Konfiguratsiyani saqlashda xato: {e}")
            return False

    def get(self, key_path, default=None):
        """Kalit yo'li bo'yicha qiymat olish (masalan: 'filters.extensions')"""
        keys = key_path.split('.')
        value = self.config
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        return value

    def set(self, key_path, value):
        """Kalit yo'li bo'yicha qiymat o'rnatish"""
        keys = key_path.split('.')
        config = self.config
        for key in keys[:-1]:
            if key not in config:
                config[key] = {}
            config = config[key]
        config[keys[-1]] = value
        self.save_config()

    def _merge_dicts(self, base, override):
        """Ikki lug'atni rekursiv birlashtirish"""
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                base[key] = self._merge_dicts(base[key], value)
            else:
                base[key] = value
        return base


# Global konfiguratsiya obyekti
config = ConfigManager()
