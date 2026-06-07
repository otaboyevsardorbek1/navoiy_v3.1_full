"""
Android Studio Loyiha Tahlilchisi - Asosiy tahlil moduli
"""
import os
import re
import json
from collections import defaultdict, Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


class CodeAnalyzer:
    """Kod tahlilchisi"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger
        self.max_workers = config_manager.get('analysis.max_workers', 4)

    def analyze_files(self, files):
        """Fayllarni tahlil qilish"""
        self.logger.info(f"{len(files)} ta fayl tahlil qilinmoqda...")

        results = []

        # Parallel tahlil
        if self.config.get('analysis.parallel', True) and len(files) > 10:
            with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
                futures = {executor.submit(self._analyze_single_file, f): f for f in files}
                for future in as_completed(futures):
                    try:
                        result = future.result()
                        if result:
                            results.append(result)
                    except Exception as e:
                        self.logger.warning(f"Fayl tahlilida xato: {e}")
        else:
            for file_info in files:
                result = self._analyze_single_file(file_info)
                if result:
                    results.append(result)

        self.logger.info(f"Tahlil yakunlandi: {len(results)} ta fayl")
        return results

    def _analyze_single_file(self, file_info):
        """Bitta faylni tahlil qilish"""
        path = file_info.get('path', '')

        try:
            # Fayl mazmunini o'qish
            if 'content' in file_info:
                content = file_info['content']
            else:
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

            lines = content.split('\n')

            # Asosiy metrikalar
            analysis = {
                'path': path,
                'relative_path': file_info.get('relative_path', path),
                'extension': os.path.splitext(path)[1].lower(),
                'size': file_info.get('size', len(content)),
                'lines': len(lines),
                'characters': len(content),
                'words': len(content.split()),
                'code_lines': len([l for l in lines if l.strip() and not l.strip().startswith('//')]),
                'comment_lines': len([l for l in lines if l.strip().startswith('//') or l.strip().startswith('*')]),
                'blank_lines': len([l for l in lines if not l.strip()]),
                'content': content[:5000]  # Birinchi 5000 belgi
            }

            # Fayl turi bo'yicha qo'shimcha tahlil
            if analysis['extension'] == '.java':
                analysis.update(self._analyze_java(content))
            elif analysis['extension'] == '.kt':
                analysis.update(self._analyze_kotlin(content))
            elif analysis['extension'] == '.xml':
                analysis.update(self._analyze_xml(content, path))
            elif analysis['extension'] in ['.gradle', '.gradle.kts']:
                analysis.update(self._analyze_gradle(content))

            return analysis

        except Exception as e:
            self.logger.warning(f"Faylni tahlil qilishda xato: {path} - {e}")
            return None

    def _analyze_java(self, content):
        """Java faylini tahlil qilish"""
        analysis = {
            'classes': len(re.findall(r'\bclass\s+\w+', content)),
            'methods': len(re.findall(r'\b(public|private|protected|static|\s)+[\w<>\[\]]+\s+\w+\s*\([^)]*\)\s*\{', content)),
            'imports': re.findall(r'^import\s+(.+?);', content, re.MULTILINE),
            'package': re.search(r'^package\s+(.+?);', content, re.MULTILINE),
            'empty_catches': len(re.findall(r'catch\s*\([^)]+\)\s*\{\s*\}', content)),
            'deprecated_usage': len(re.findall(r'@Deprecated', content)),
            'todo_comments': len(re.findall(r'//\s*TODO', content, re.IGNORECASE))
        }

        if analysis['package']:
            analysis['package'] = analysis['package'].group(1)

        return analysis

    def _analyze_kotlin(self, content):
        """Kotlin faylini tahlil qilish"""
        analysis = {
            'classes': len(re.findall(r'\bclass\s+\w+', content)),
            'functions': len(re.findall(r'\bfun\s+\w+', content)),
            'imports': re.findall(r'^import\s+(.+?)$', content, re.MULTILINE),
            'package': re.search(r'^package\s+(.+?)$', content, re.MULTILINE),
            'empty_catches': len(re.findall(r'catch\s*\([^)]+\)\s*\{\s*\}', content)),
            'coroutines': len(re.findall(r'\bsuspend\b|\brunBlocking\b|\blaunch\b|\basync\b', content)),
            'todo_comments': len(re.findall(r'//\s*TODO', content, re.IGNORECASE))
        }

        if analysis['package']:
            analysis['package'] = analysis['package'].group(1)

        return analysis

    def _analyze_xml(self, content, path):
        """XML faylini tahlil qilish"""
        analysis = {
            'tags': len(re.findall(r'<\w+', content)),
            'view_ids': re.findall(r'android:id="@\+id/([^"]+)"', content),
            'strings': re.findall(r'android:text="([^"]+)"', content),
            'references': re.findall(r'@\+(id|string|drawable|layout|color)/([^"]+)', content)
        }

        # Layout fayli ekanligini tekshirish
        if 'res/layout' in path:
            analysis['is_layout'] = True
            analysis['view_count'] = len(re.findall(r'<[A-Z]\w+', content))

        # Manifest fayli
        if 'AndroidManifest.xml' in path:
            analysis['is_manifest'] = True
            analysis['permissions'] = re.findall(r'<uses-permission android:name="([^"]+)"', content)
            analysis['activities'] = re.findall(r'<activity\s+android:name="([^"]+)"', content)
            analysis['services'] = re.findall(r'<service\s+android:name="([^"]+)"', content)
            analysis['receivers'] = re.findall(r'<receiver\s+android:name="([^"]+)"', content)
            analysis['package_name'] = re.search(r'package="([^"]+)"', content)
            if analysis['package_name']:
                analysis['package_name'] = analysis['package_name'].group(1)

        # Strings fayli
        if 'res/values/strings.xml' in path:
            analysis['is_strings'] = True
            analysis['string_resources'] = re.findall(r'<string\s+name="([^"]+)"[^>]*>([^<]*)</string>', content)

        return analysis

    def _analyze_gradle(self, content):
        """Gradle faylini tahlil qilish"""
        analysis = {
            'dependencies': re.findall(r'(implementation|api|compileOnly|testImplementation|androidTestImplementation)\s+["\']([^"\']+)["\']', content),
            'plugins': re.findall(r'apply\s+plugin:\s*["\']([^"\']+)["\']', content),
            'sdk_versions': {}
        }

        # SDK versiyalari
        compile_sdk = re.search(r'compileSdk\s*=?\s*(\d+)', content)
        if compile_sdk:
            analysis['sdk_versions']['compileSdk'] = int(compile_sdk.group(1))

        min_sdk = re.search(r'minSdk\s*=?\s*(\d+)', content)
        if min_sdk:
            analysis['sdk_versions']['minSdk'] = int(min_sdk.group(1))

        target_sdk = re.search(r'targetSdk\s*=?\s*(\d+)', content)
        if target_sdk:
            analysis['sdk_versions']['targetSdk'] = int(target_sdk.group(1))

        # Application ID
        app_id = re.search(r'applicationId\s*["\']([^"\']+)["\']', content)
        if app_id:
            analysis['application_id'] = app_id.group(1)

        # Version
        version_code = re.search(r'versionCode\s*(\d+)', content)
        if version_code:
            analysis['version_code'] = int(version_code.group(1))

        version_name = re.search(r'versionName\s*["\']([^"\']+)["\']', content)
        if version_name:
            analysis['version_name'] = version_name.group(1)

        # ProGuard
        analysis['proguard_enabled'] = 'proguardFiles' in content

        return analysis


class ModuleAnalyzer:
    """Modul tahlilchisi"""

    def __init__(self, logger):
        self.logger = logger

    def analyze_modules(self, analyzed_files):
        """Modullarni aniqlash va tahlil qilish"""
        self.logger.info("Modullar tahlil qilinmoqda...")

        modules = defaultdict(lambda: {
            'files': [],
            'total_lines': 0,
            'total_size': 0,
            'gradle_info': {},
            'manifest_info': {}
        })

        for file_info in analyzed_files:
            path = file_info.get('path', '')

            # Modulni aniqlash (build.gradle fayli bor papka)
            module_name = self._detect_module(path)

            modules[module_name]['files'].append(file_info)
            modules[module_name]['total_lines'] += file_info.get('lines', 0)
            modules[module_name]['total_size'] += file_info.get('size', 0)

            # Gradle ma'lumotlarini saqlash
            if file_info.get('extension') in ['.gradle', '.gradle.kts']:
                modules[module_name]['gradle_info'] = {
                    'dependencies': file_info.get('dependencies', []),
                    'sdk_versions': file_info.get('sdk_versions', {}),
                    'application_id': file_info.get('application_id', ''),
                    'version_code': file_info.get('version_code', 0),
                    'version_name': file_info.get('version_name', ''),
                    'proguard_enabled': file_info.get('proguard_enabled', False)
                }

            # Manifest ma'lumotlarini saqlash
            if 'AndroidManifest.xml' in path:
                modules[module_name]['manifest_info'] = {
                    'package_name': file_info.get('package_name', ''),
                    'permissions': file_info.get('permissions', []),
                    'activities': file_info.get('activities', []),
                    'services': file_info.get('services', []),
                    'receivers': file_info.get('receivers', [])
                }

        return dict(modules)

    def _detect_module(self, path):
        """Fayl yo'li asosida modul nomini aniqlash"""
        parts = path.replace('\\', '/').split('/')

        # build.gradle fayli bor papkani modul deb hisoblash
        for i, part in enumerate(parts):
            if i > 0:
                potential_module = parts[i-1]
                # Agar bu app, feature, library, core bo'lsa
                if potential_module in ['app', 'feature', 'library', 'core', 'data', 'domain', 'presentation']:
                    return potential_module

        # Agar build.gradle app papkasida bo'lsa
        if 'app/' in path:
            return 'app'

        # Default: papka nomini qaytarish
        if len(parts) > 2:
            return parts[-2]

        return 'root'


class ResourceAnalyzer:
    """Resurslar tahlilchisi"""

    def __init__(self, logger):
        self.logger = logger

    def analyze_resources(self, analyzed_files):
        """Resurslarni tahlil qilish"""
        self.logger.info("Resurslar tahlil qilinmoqda...")

        resources = {
            'layouts': {},
            'strings': {},
            'drawables': [],
            'values': {},
            'duplicates': {}
        }

        all_layouts = []
        all_strings = []

        for file_info in analyzed_files:
            path = file_info.get('path', '')

            # Layout fayllari
            if 'res/layout' in path and file_info.get('is_layout'):
                layout_name = os.path.basename(path)
                all_layouts.append(layout_name)
                resources['layouts'][layout_name] = {
                    'view_count': file_info.get('view_count', 0),
                    'view_ids': file_info.get('view_ids', []),
                    'strings': file_info.get('strings', [])
                }

            # Strings fayllari
            if file_info.get('is_strings'):
                for name, value in file_info.get('string_resources', []):
                    all_strings.append(name)
                    resources['strings'][name] = value

            # Drawable fayllari
            if 'res/drawable' in path or 'res/mipmap' in path:
                resources['drawables'].append({
                    'name': os.path.basename(path),
                    'path': path,
                    'size': file_info.get('size', 0)
                })

        # Takrorlangan resurslarni topish
        from collections import Counter
        layout_counts = Counter(all_layouts)
        string_counts = Counter(all_strings)

        resources['duplicates'] = {
            'layouts': {k: v for k, v in layout_counts.items() if v > 1},
            'strings': {k: v for k, v in string_counts.items() if v > 1}
        }

        return resources
