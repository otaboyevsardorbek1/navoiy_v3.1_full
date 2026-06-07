"""
Android Studio Loyiha Tahlilchisi - Log tizimi
"""
import logging
import os
import sys
from datetime import datetime
from logging.handlers import RotatingFileHandler


class ColoredFormatter(logging.Formatter):
    """Rangli log formatlash"""

    COLORS = {
        'DEBUG': '[36m',      # Cyan
        'INFO': '[32m',       # Green
        'WARNING': '[33m',    # Yellow
        'ERROR': '[31m',      # Red
        'CRITICAL': '[35m',   # Magenta
        'RESET': '[0m'
    }

    def format(self, record):
        log_color = self.COLORS.get(record.levelname, self.COLORS['RESET'])
        reset = self.COLORS['RESET']
        record.levelname = f"{log_color}{record.levelname}{reset}"
        return super().format(record)


class LoggerManager:
    """Log tizimini boshqarish"""

    def __init__(self, config_manager):
        self.config = config_manager
        self.logger = self._setup_logger()

    def _setup_logger(self):
        """Loggerni sozlash"""
        logger = logging.getLogger('android_extractor')
        logger.setLevel(getattr(logging, self.config.get('logging.level', 'INFO')))

        # Agar handlerlar allaqachon qo'shilgan bo'lsa
        if logger.handlers:
            return logger

        # Format
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

        # Konsol handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.DEBUG)
        colored_formatter = ColoredFormatter(
            '%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%H:%M:%S'
        )
        console_handler.setFormatter(colored_formatter)
        logger.addHandler(console_handler)

        # Fayl handler
        log_file = self.config.get('logging.file', 'android_extractor.log')
        max_size = self.config.get('logging.max_size_mb', 10) * 1024 * 1024
        backup_count = self.config.get('logging.backup_count', 5)

        file_handler = RotatingFileHandler(
            log_file, maxBytes=max_size, backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        return logger

    def debug(self, message):
        self.logger.debug(message)

    def info(self, message):
        self.logger.info(message)

    def warning(self, message):
        self.logger.warning(message)

    def error(self, message):
        self.logger.error(message)

    def critical(self, message):
        self.logger.critical(message)

    def log_exception(self, exc):
        """Istisnoni loglash"""
        self.logger.exception(f"Xatolik: {exc}")
