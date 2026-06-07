#!/usr/bin/env python3
"""
Android Studio Loyiha Tahlilchisi
====================================
Android Studio loyihalarini tahlil qiluvchi universal dastur.

Qo'llab-quvvatlanadigan manbalar:
- JSON fayllar (loyiha tuzilmasi)
- ZIP arxivlar
- Android loyiha papkalari

Chiqish formatlari:
- TXT - Matnli hisobot
- CSV - Jadval ma'lumotlari
- JSON - Mashina o'qiy oladigan format
- HTML - Interaktiv veb-hisobot
- Markdown - GitHub/README uchun

Foydalanish:
    python android_extractor.py                    # GUI rejimi
    python android_extractor.py --source <path>      # Buyruq satri rejimi

Avtor: Android Extractor Team
Versiya: 1.0.0
"""

import os
import sys
import argparse
from pathlib import Path

# Modullarni import qilish
try:
    from modules.config import ConfigManager
    from modules.logger import LoggerManager
    from modules.file_scanner import FileScanner
    from modules.analyzer import CodeAnalyzer, ModuleAnalyzer, ResourceAnalyzer
    from modules.report_generator import ReportGenerator
    from modules.gui import AndroidExtractorGUI
    from modules.cache_manager import CacheManager
    from modules.notifications import NotificationManager
    from modules.integrations import GitIntegration, JiraIntegration, BackupManager
except ImportError as e:
    print(f"Xato: Kerakli modullar topilmadi: {e}")
    print("Iltimos, barcha modullar to'g'ri joylashtirilganini tekshiring.")
    sys.exit(1)


__version__ = "1.0.0"
__author__ = "Android Extractor Team"


class AndroidExtractor:
    """
    Android Studio Loyiha Tahlilchisi - Asosiy klass

    Bu klass barcha tahlil funksiyalarini birlashtiradi va boshqaradi.
    """

    def __init__(self, config_path="config.json"):
        """
        Extractor ni ishga tushirish

        Args:
            config_path: Konfiguratsiya fayli yo'li
        """
        self.config = ConfigManager(config_path)
        self.logger = LoggerManager(self.config)
        self.scanner = FileScanner(self.config, self.logger)
        self.analyzer = CodeAnalyzer(self.config, self.logger)
        self.module_analyzer = ModuleAnalyzer(self.logger)
        self.resource_analyzer = ResourceAnalyzer(self.logger)
        self.reporter = ReportGenerator(self.config, self.logger)
        self.cache = CacheManager(self.config, self.logger)
        self.notifier = NotificationManager(self.config, self.logger)
        self.git = GitIntegration(self.config, self.logger)
        self.jira = JiraIntegration(self.config, self.logger)
        self.backup = BackupManager(self.config, self.logger)

        self.logger.info(f"Android Extractor v{__version__} ishga tushdi")

    def run_analysis(self, source_path, options=None):
        """
        Tahlilni ishga tushirish

        Args:
            source_path: Manba yo'li (JSON, ZIP, yoki papka)
            options: Tahlil opsiyalari (dict)

        Returns:
            dict: Tahlil natijalari
        """
        if options is None:
            options = {}

        self.logger.info(f"Tahlil boshlandi: {source_path}")

        # Keshni tekshirish
        if not options.get('no_cache', False):
            cached = self.cache.get_cached_result(source_path, options)
            if cached:
                self.logger.info("Keshdan natija yuklandi!")
                return cached

        try:
            # 1. Fayllarni skanerlash
            self.logger.info("Fayllar skanerlanmoqda...")
            files = self.scanner.scan_source(source_path)

            # Filtrlash
            if options.get('extensions'):
                ext_list = [e.strip() for e in options['extensions'].split(',')]
                files = [f for f in files if any(f.get('path', '').endswith(ext) for ext in ext_list)]

            if options.get('filter_folder'):
                files = self.scanner.filter_by_folder(files, options['filter_folder'])

            if options.get('regex'):
                files = self.scanner.filter_by_regex(files, options['regex'])

            self.logger.info(f"Filtrlangan: {len(files)} ta fayl")

            # 2. Fayllarni tahlil qilish
            self.logger.info("Fayllar tahlil qilinmoqda...")
            analyzed = self.analyzer.analyze_files(files)

            # 3. Modullarni tahlil qilish
            modules = {}
            if options.get('modules', True):
                self.logger.info("Modullar tahlil qilinmoqda...")
                modules = self.module_analyzer.analyze_modules(analyzed)

            # 4. Resurslarni tahlil qilish
            resources = {}
            if options.get('resources', True):
                self.logger.info("Resurslar tahlil qilinmoqda...")
                resources = self.resource_analyzer.analyze_resources(analyzed)

            # 5. Hisobotlarni yaratish
            formats = options.get('output_format', ['txt', 'json', 'html'])
            if isinstance(formats, str):
                formats = [f.strip() for f in formats.split(',')]

            self.logger.info(f"Hisobotlar yaratilmoqda: {formats}")
            generated = self.reporter.generate_all_reports(analyzed, modules, resources, formats)

            # 6. Natijalarni tayyorlash
            results = {
                'total_files': len(analyzed),
                'total_lines': sum(f.get('lines', 0) for f in analyzed),
                'total_size': sum(f.get('size', 0) for f in analyzed),
                'modules': len(modules),
                'generated_files': generated,
                'analyzed_files': analyzed,
                'modules_data': modules,
                'resources_data': resources
            }

            # 7. Keshga saqlash
            if not options.get('no_cache', False):
                self.cache.save_result(source_path, results, options)

            # 8. Backup yaratish
            if self.config.get('output.auto_backup', True):
                self.backup.create_backup(generated)

            # 9. Git commit
            if options.get('git_commit', False):
                if self.git.is_git_repo(os.path.dirname(source_path) if os.path.isfile(source_path) else source_path):
                    self.git.auto_commit(generated)

            # 10. Xabar yuborish
            self.notifier.notify_analysis_complete(results, generated)

            self.logger.info("Tahlil muvaffaqiyatli yakunlandi!")
            return results

        except Exception as e:
            self.logger.error(f"Tahlil davomida xato: {e}")
            raise

    def print_results(self, results):
        """Natijalarni konsolga chiqarish"""
        print("\n" + "=" * 60)
        print("ANDROID STUDIO LOYIHA TAHLILI - NATIJALAR")
        print("=" * 60)
        print(f"Jami fayllar: {results['total_files']}")
        print(f"Jami qatorlar: {results['total_lines']:,}")
        print(f"Jami hajm: {self._format_size(results['total_size'])}")
        print(f"Modullar: {results['modules']}")
        print("\nYaratilgan hisobotlar:")
        for path in results['generated_files']:
            print(f"  - {path}")
        print("=" * 60 + "\n")

    def _format_size(self, size_bytes):
        """Hajmni formatlash"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"


def create_sample_config():
    """Namuna konfiguratsiya fayli yaratish"""
    config_content = {
        "filters": {
            "extensions": [
                ".java", ".kt", ".xml", ".gradle", ".properties", ".pro",
                ".aidl", ".gitignore", ".md", ".gradle.kts", ".iml"
            ],
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
        }
    }

    with open('config.json', 'w', encoding='utf-8') as f:
        import json
        json.dump(config_content, f, indent=2, ensure_ascii=False)

    print("Namuna konfiguratsiya fayli yaratildi: config.json")


def main():
    """Asosiy funksiya - buyruq satri argumentlarini qayta ishlash"""
    parser = argparse.ArgumentParser(
        description='Android Studio Loyiha Tahlilchisi',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Foydalanish misollari:
  GUI rejimi:
    python android_extractor.py

  JSON dan TXT hisobot:
    python android_extractor.py --source project_structure.json --output-format txt

  Papkani skanerlab, CSV va HTML hisobot:
    python android_extractor.py --source /path/to/android/project --output-format csv,html --modules --manifest --gradle

  ZIP arxivdan faqat statistika, parallel ishlov:
    python android_extractor.py --source project.zip --stats-only --parallel

  Regex bilan filtrlash:
    python android_extractor.py --source ./project --regex "MainActivity.*\\.java" --output-format json
        """
    )

    # Asosiy argumentlar
    parser.add_argument(
        '--source', '-s',
        help="Manba yo'li (JSON, ZIP, yoki papka)"
    )

    parser.add_argument(
        '--output-format', '-o',
        default='txt,json,html',
        help="Chiqish formatlari (vergul bilan ajratilgan): txt, csv, json, html, md"
    )

    # Filtr argumentlari
    parser.add_argument(
        '--extensions', '-e',
        help="Fayl kengaytmalari (vergul bilan ajratilgan): .java,.kt,.xml"
    )

    parser.add_argument(
        '--filter-folder', '-f',
        help="Faqat berilgan papkadagi fayllar"
    )

    parser.add_argument(
        '--regex', '-r',
        help="Regex asosida fayl filtrlash"
    )

    # Tahlil opsiyalari
    parser.add_argument(
        '--stats-only',
        action='store_true',
        help='Faqat statistika (fayl mazmunisiz)'
    )

    parser.add_argument(
        '--modules', '-m',
        action='store_true',
        default=True,
        help='Modul tahlilini yoqish'
    )

    parser.add_argument(
        '--no-modules',
        action='store_true',
        help="Modul tahlilini o'chirish"
    )

    parser.add_argument(
        '--manifest',
        action='store_true',
        default=True,
        help='Manifest tahlilini yoqish'
    )

    parser.add_argument(
        '--gradle', '-g',
        action='store_true',
        default=True,
        help='Gradle tahlilini yoqish'
    )

    parser.add_argument(
        '--resources',
        action='store_true',
        default=True,
        help='Resurslar tahlilini yoqish'
    )

    parser.add_argument(
        '--lint', '-l',
        action='store_true',
        help='Kod sifat tekshiruvi'
    )

    # Performance
    parser.add_argument(
        '--parallel', '-p',
        action='store_true',
        default=True,
        help='Parallel ishlash'
    )

    parser.add_argument(
        '--no-parallel',
        action='store_true',
        help="Parallel ishlashni o'chirish"
    )

    parser.add_argument(
        '--no-cache',
        action='store_true',
        help="Keshni ishlatmaslik"
    )

    # Integratsiyalar
    parser.add_argument(
        '--git-commit',
        action='store_true',
        help='Git avtomatik commit'
    )

    parser.add_argument(
        '--create-config',
        action='store_true',
        help='Namuna konfiguratsiya fayli yaratish'
    )

    # Log darajasi
    parser.add_argument(
        '--log-level',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        default='INFO',
        help='Log darajasi'
    )

    parser.add_argument(
        '--version', '-v',
        action='version',
        version=f'Android Extractor v{__version__}'
    )

    args = parser.parse_args()

    # Namuna konfiguratsiya yaratish
    if args.create_config:
        create_sample_config()
        return

    # GUI rejimi (agar manba ko'rsatilmagan bo'lsa)
    if not args.source:
        print("Manba ko'rsatilmagan. GUI rejimi ishga tushirilmoqda...")
        print("(Buyruq satri rejimi uchun --source argumentini ishlating)")

        extractor = AndroidExtractor()
        gui = AndroidExtractorGUI(extractor)
        gui.run()
        return

    # Buyruq satri rejimi
    extractor = AndroidExtractor()

    # Log darajasini sozlash
    if args.log_level:
        extractor.config.set('logging.level', args.log_level)
        extractor.logger = LoggerManager(extractor.config)

    # Opsiyalarni tayyorlash
    options = {
        'output_format': args.output_format,
        'extensions': args.extensions,
        'filter_folder': args.filter_folder,
        'regex': args.regex,
        'stats_only': args.stats_only,
        'modules': not args.no_modules if args.no_modules else args.modules,
        'manifest': args.manifest,
        'gradle': args.gradle,
        'resources': args.resources,
        'lint': args.lint,
        'parallel': not args.no_parallel if args.no_parallel else args.parallel,
        'no_cache': args.no_cache,
        'git_commit': args.git_commit
    }

    try:
        # Tahlilni ishga tushirish
        results = extractor.run_analysis(args.source, options)

        # Natijalarni chiqarish
        extractor.print_results(results)

        print("Tahlil muvaffaqiyatli yakunlandi!")

    except FileNotFoundError as e:
        print(f"Xato: {e}")
        print("Iltimos, manba yo'lini tekshiring.")
        sys.exit(1)
    except Exception as e:
        print(f"Kutilmagan xato: {e}")
        extractor.logger.error(f"Kutilmagan xato: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
