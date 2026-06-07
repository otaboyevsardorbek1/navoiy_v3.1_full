"""
Android Studio Loyiha Tahlilchisi - Hisobot yaratish moduli
"""
import os
import json
import csv
import html as html_module
from datetime import datetime
from collections import defaultdict


class ReportGenerator:
    """Hisobot yaratish"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger
        self.output_dir = config_manager.get('output.directory', 'output')
        os.makedirs(self.output_dir, exist_ok=True)

    def generate_all_reports(self, analyzed_files, modules, resources, formats=None):
        """Barcha formatlarda hisobot yaratish"""
        if formats is None:
            formats = self.config.get('output.formats', ['txt', 'json', 'html'])

        self.logger.info(f"Hisobotlar yaratilmoqda: {formats}")

        generated_files = []

        for fmt in formats:
            try:
                if fmt == 'txt':
                    path = self._generate_txt(analyzed_files, modules, resources)
                elif fmt == 'csv':
                    path = self._generate_csv(analyzed_files)
                elif fmt == 'json':
                    path = self._generate_json(analyzed_files, modules, resources)
                elif fmt == 'html':
                    path = self._generate_html(analyzed_files, modules, resources)
                elif fmt == 'md':
                    path = self._generate_markdown(analyzed_files, modules, resources)
                else:
                    self.logger.warning(f"Qo'llab-quvvatlanmaydigan format: {fmt}")
                    continue

                generated_files.append(path)
                self.logger.info(f"Hisobot yaratildi: {path}")

            except Exception as e:
                self.logger.error(f"Hisobot yaratishda xato ({fmt}): {e}")

        return generated_files

    def _generate_txt(self, analyzed_files, modules, resources):
        """TXT formatida hisobot"""
        output_path = os.path.join(self.output_dir, 'report.txt')

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("ANDROID STUDIO LOYIHA TAHLILI\n")
            f.write(f"Sana: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")

            total_files = len(analyzed_files)
            total_lines = sum(f.get('lines', 0) for f in analyzed_files)
            total_size = sum(f.get('size', 0) for f in analyzed_files)

            f.write("UMUMIY STATISTIKA\n")
            f.write("-" * 40 + "\n")
            f.write(f"Jami fayllar: {total_files}\n")
            f.write(f"Jami qatorlar: {total_lines:,}\n")
            f.write(f"Jami hajm: {self._format_size(total_size)}\n")
            f.write(f"O'rtacha qatorlar/fayl: {total_lines // total_files if total_files else 0}\n")
            f.write("\n")

            f.write("FAYL TURLARI BO'YICHA TAQLIMOT\n")
            f.write("-" * 40 + "\n")
            ext_counts = defaultdict(int)
            ext_lines = defaultdict(int)
            for file_info in analyzed_files:
                ext = file_info.get('extension', "Noma'lum")
                ext_counts[ext] += 1
                ext_lines[ext] += file_info.get('lines', 0)

            for ext, count in sorted(ext_counts.items(), key=lambda x: x[1], reverse=True):
                f.write(f"{ext}: {count} ta fayl ({ext_lines[ext]:,} qator)\n")
            f.write("\n")

            f.write("TOP 10 ENG KATTA FAYLLAR\n")
            f.write("-" * 40 + "\n")
            sorted_files = sorted(analyzed_files, key=lambda x: x.get('lines', 0), reverse=True)[:10]
            for i, file_info in enumerate(sorted_files, 1):
                f.write(f"{i}. {file_info.get('relative_path', file_info['path'])}\n")
                f.write(f"   Qatorlar: {file_info.get('lines', 0):,} | "
                       f"Belgilar: {file_info.get('characters', 0):,} | "
                       f"So'zlar: {file_info.get('words', 0):,}\n")
            f.write("\n")

            if modules:
                f.write("MODULLAR TAHLILI\n")
                f.write("-" * 40 + "\n")
                for module_name, module_info in modules.items():
                    f.write(f"\n>>> {module_name}\n")
                    f.write(f"    Fayllar: {len(module_info['files'])}\n")
                    f.write(f"    Jami qatorlar: {module_info['total_lines']:,}\n")
                    f.write(f"    Jami hajm: {self._format_size(module_info['total_size'])}\n")

                    if module_info['gradle_info']:
                        gradle = module_info['gradle_info']
                        f.write(f"    Application ID: {gradle.get('application_id', 'N/A')}\n")
                        f.write(f"    Version: {gradle.get('version_name', 'N/A')} ({gradle.get('version_code', 'N/A')})\n")
                        f.write(f"    SDK: compile={gradle.get('sdk_versions', {}).get('compileSdk', 'N/A')}, "
                               f"min={gradle.get('sdk_versions', {}).get('minSdk', 'N/A')}, "
                               f"target={gradle.get('sdk_versions', {}).get('targetSdk', 'N/A')}\n")
                        f.write(f"    Dependencies: {len(gradle.get('dependencies', []))} ta\n")
                        f.write(f"    ProGuard: {'Yoniq' if gradle.get('proguard_enabled') else 'Ochiq'}\n")

                    if module_info['manifest_info']:
                        manifest = module_info['manifest_info']
                        f.write(f"    Package: {manifest.get('package_name', 'N/A')}\n")
                        f.write(f"    Permissions: {len(manifest.get('permissions', []))}\n")
                        f.write(f"    Activities: {len(manifest.get('activities', []))}\n")
                        f.write(f"    Services: {len(manifest.get('services', []))}\n")
                f.write("\n")

            if resources:
                f.write("RESURSLAR TAHLILI\n")
                f.write("-" * 40 + "\n")
                f.write(f"Layout fayllar: {len(resources.get('layouts', {}))}\n")
                f.write(f"String resurslar: {len(resources.get('strings', {}))}\n")
                f.write(f"Drawable fayllar: {len(resources.get('drawables', []))}\n")

                duplicates = resources.get('duplicates', {})
                if duplicates.get('layouts') or duplicates.get('strings'):
                    f.write("\nTAKRORLANGAN RESURSLAR:\n")
                    for name, count in duplicates.get('layouts', {}).items():
                        f.write(f"  Layout '{name}': {count} marta\n")
                    for name, count in duplicates.get('strings', {}).items():
                        f.write(f"  String '{name}': {count} marta\n")

            f.write("\n" + "=" * 80 + "\n")
            f.write("Hisobot yakunlandi.\n")

        return output_path

    def _generate_csv(self, analyzed_files):
        """CSV formatida hisobot"""
        output_path = os.path.join(self.output_dir, 'report.csv')

        with open(output_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([
                'Path', 'Extension', 'Size (bytes)', 'Lines', 'Characters',
                'Words', 'Code Lines', 'Comment Lines', 'Blank Lines', 'Module'
            ])

            for file_info in analyzed_files:
                writer.writerow([
                    file_info.get('relative_path', file_info.get('path', '')),
                    file_info.get('extension', ''),
                    file_info.get('size', 0),
                    file_info.get('lines', 0),
                    file_info.get('characters', 0),
                    file_info.get('words', 0),
                    file_info.get('code_lines', 0),
                    file_info.get('comment_lines', 0),
                    file_info.get('blank_lines', 0),
                    self._detect_module(file_info.get('path', ''))
                ])

        return output_path

    def _generate_json(self, analyzed_files, modules, resources):
        """JSON formatida hisobot"""
        output_path = os.path.join(self.output_dir, 'report.json')

        report = {
            'generated_at': datetime.now().isoformat(),
            'summary': {
                'total_files': len(analyzed_files),
                'total_lines': sum(f.get('lines', 0) for f in analyzed_files),
                'total_size': sum(f.get('size', 0) for f in analyzed_files),
                'file_types': self._get_file_type_stats(analyzed_files)
            },
            'files': analyzed_files,
            'modules': modules,
            'resources': resources
        }

        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False, default=str)

        return output_path

    def _generate_html(self, analyzed_files, modules, resources):
        """HTML formatida interaktiv hisobot"""
        output_path = os.path.join(self.output_dir, 'report.html')

        total_files = len(analyzed_files)
        total_lines = sum(f.get('lines', 0) for f in analyzed_files)
        total_size = sum(f.get('size', 0) for f in analyzed_files)
        ext_stats = self._get_file_type_stats(analyzed_files)

        css_styles = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f7fa; color: #333; line-height: 1.6; }
.container { max-width: 1400px; margin: 0 auto; padding: 20px; }
header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; border-radius: 16px; margin-bottom: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
header h1 { font-size: 2.5em; margin-bottom: 10px; }
header p { opacity: 0.9; font-size: 1.1em; }
.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
.stat-card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); transition: transform 0.2s; }
.stat-card:hover { transform: translateY(-5px); box-shadow: 0 5px 20px rgba(0,0,0,0.1); }
.stat-card .number { font-size: 2.5em; font-weight: bold; color: #667eea; }
.stat-card .label { color: #666; font-size: 0.95em; margin-top: 5px; }
.section { background: white; padding: 30px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
.section h2 { color: #333; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #667eea; }
table { width: 100%; border-collapse: collapse; margin-top: 15px; }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
th { background: #f8f9fa; font-weight: 600; color: #555; position: sticky; top: 0; }
tr:hover { background: #f8f9fa; }
.search-box { width: 100%; padding: 12px 16px; border: 2px solid #e0e0e0; border-radius: 8px; font-size: 1em; margin-bottom: 15px; transition: border-color 0.3s; }
.search-box:focus { outline: none; border-color: #667eea; }
.badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 0.85em; font-weight: 500; }
.badge-blue { background: #e3f2fd; color: #1976d2; }
.badge-green { background: #e8f5e9; color: #388e3c; }
.badge-orange { background: #fff3e0; color: #f57c00; }
.badge-red { background: #ffebee; color: #d32f2f; }
.progress-bar { width: 100%; height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; }
.progress-fill { height: 100%; background: linear-gradient(90deg, #667eea, #764ba2); border-radius: 4px; transition: width 0.5s ease; }
.tabs { display: flex; gap: 10px; margin-bottom: 20px; border-bottom: 2px solid #e0e0e0; }
.tab { padding: 10px 20px; cursor: pointer; border-bottom: 2px solid transparent; transition: all 0.3s; }
.tab.active { color: #667eea; border-bottom-color: #667eea; }
.tab:hover { color: #667eea; }
.tab-content { display: none; }
.tab-content.active { display: block; }
footer { text-align: center; padding: 30px; color: #999; margin-top: 40px; }
@media (max-width: 768px) { .stats-grid { grid-template-columns: 1fr; } header h1 { font-size: 1.8em; } table { font-size: 0.9em; } }
"""

        html_parts = []
        html_parts.append('<!DOCTYPE html>')
        html_parts.append('<html lang="uz">')
        html_parts.append('<head>')
        html_parts.append('<meta charset="UTF-8">')
        html_parts.append('<meta name="viewport" content="width=device-width, initial-scale=1.0">')
        html_parts.append('<title>Android Studio Loyiha Tahlili</title>')
        html_parts.append(f'<style>{css_styles}</style>')
        html_parts.append('</head>')
        html_parts.append('<body>')
        html_parts.append('<div class="container">')

        # Header
        html_parts.append('<header>')
        html_parts.append('<h1>Android Studio Loyiha Tahlili</h1>')
        html_parts.append(f'<p>Yaratilgan sana: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>')
        html_parts.append('</header>')

        # Stats grid
        html_parts.append('<div class="stats-grid">')
        html_parts.append(f'<div class="stat-card"><div class="number">{total_files:,}</div><div class="label">Jami fayllar</div></div>')
        html_parts.append(f'<div class="stat-card"><div class="number">{total_lines:,}</div><div class="label">Jami qatorlar</div></div>')
        html_parts.append(f'<div class="stat-card"><div class="number">{self._format_size(total_size)}</div><div class="label">Jami hajm</div></div>')
        html_parts.append(f'<div class="stat-card"><div class="number">{len(modules)}</div><div class="label">Modullar</div></div>')
        html_parts.append('</div>')

        # File types section
        html_parts.append('<div class="section">')
        html_parts.append("<h2>Fayl Turlari Bo'yicha Taqsimot</h2>")
        html_parts.append('<table>')
        html_parts.append('<tr><th>Kengaytma</th><th>Fayllar soni</th><th>Qatorlar</th><th>Ulushi</th></tr>')

        for ext, stats in sorted(ext_stats.items(), key=lambda x: x[1]['count'], reverse=True):
            percentage = (stats['count'] / total_files * 100) if total_files else 0
            html_parts.append('<tr>')
            html_parts.append(f'<td><span class="badge badge-blue">{ext}</span></td>')
            html_parts.append(f'<td>{stats["count"]:,}</td>')
            html_parts.append(f'<td>{stats["lines"]:,}</td>')
            html_parts.append(f'<td><div class="progress-bar"><div class="progress-fill" style="width: {percentage}%"></div></div><small>{percentage:.1f}%</small></td>')
            html_parts.append('</tr>')

        html_parts.append('</table>')
        html_parts.append('</div>')

        # TOP files section
        html_parts.append('<div class="section">')
        html_parts.append("<h2>TOP 20 Eng Katta Fayllar</h2>")
        html_parts.append('<input type="text" class="search-box" id="fileSearch" placeholder="Fayllarni qidirish..." onkeyup="searchFiles()">')
        html_parts.append('<div style="overflow-x: auto;">')
        html_parts.append('<table id="filesTable">')
        html_parts.append("<tr><th>#</th><th>Fayl yo'li</th><th>Kengaytma</th><th>Qatorlar</th><th>Belgilar</th><th>So'zlar</th></tr>")

        sorted_files = sorted(analyzed_files, key=lambda x: x.get('lines', 0), reverse=True)[:20]
        for i, file_info in enumerate(sorted_files, 1):
            rel_path = html_module.escape(file_info.get('relative_path', file_info.get('path', '')))
            html_parts.append('<tr>')
            html_parts.append(f'<td>{i}</td>')
            html_parts.append(f'<td>{rel_path}</td>')
            html_parts.append(f'<td><span class="badge badge-green">{file_info.get("extension", "")}</span></td>')
            html_parts.append(f'<td>{file_info.get("lines", 0):,}</td>')
            html_parts.append(f'<td>{file_info.get("characters", 0):,}</td>')
            html_parts.append(f'<td>{file_info.get("words", 0):,}</td>')
            html_parts.append('</tr>')

        html_parts.append('</table>')
        html_parts.append('</div>')
        html_parts.append('</div>')

        # Modules section
        html_parts.append('<div class="section">')
        html_parts.append('<h2>Modullar Tahlili</h2>')
        html_parts.append('<div class="tabs">')
        html_parts.append('<div class="tab active" onclick="showTab(\'modules-overview\')">Umumiy</div>')
        html_parts.append('<div class="tab" onclick="showTab(\'modules-details\')">Batafsil</div>')
        html_parts.append('</div>')

        html_parts.append('<div id="modules-overview" class="tab-content active">')
        html_parts.append('<table>')
        html_parts.append('<tr><th>Modul</th><th>Fayllar</th><th>Qatorlar</th><th>Hajm</th><th>Dependencies</th></tr>')

        for module_name, module_info in modules.items():
            deps_count = len(module_info.get('gradle_info', {}).get('dependencies', []))
            html_parts.append('<tr>')
            html_parts.append(f'<td><strong>{module_name}</strong></td>')
            html_parts.append(f'<td>{len(module_info["files"])}</td>')
            html_parts.append(f'<td>{module_info["total_lines"]:,}</td>')
            html_parts.append(f'<td>{self._format_size(module_info["total_size"])}</td>')
            html_parts.append(f'<td><span class="badge badge-orange">{deps_count}</span></td>')
            html_parts.append('</tr>')

        html_parts.append('</table>')
        html_parts.append('</div>')

        html_parts.append('<div id="modules-details" class="tab-content">')
        for module_name, module_info in modules.items():
            gradle = module_info.get('gradle_info', {})
            manifest = module_info.get('manifest_info', {})
            html_parts.append('<div style="margin-bottom: 20px; padding: 15px; background: #f8f9fa; border-radius: 8px;">')
            html_parts.append(f'<h3 style="color: #667eea; margin-bottom: 10px;">{module_name}</h3>')
            html_parts.append(f'<p><strong>Application ID:</strong> {gradle.get("application_id", "N/A")}</p>')
            html_parts.append(f'<p><strong>Version:</strong> {gradle.get("version_name", "N/A")} ({gradle.get("version_code", "N/A")})</p>')
            html_parts.append(f'<p><strong>Package:</strong> {manifest.get("package_name", "N/A")}</p>')
            html_parts.append(f'<p><strong>SDK:</strong> compile={gradle.get("sdk_versions", {}).get("compileSdk", "N/A")}, min={gradle.get("sdk_versions", {}).get("minSdk", "N/A")}, target={gradle.get("sdk_versions", {}).get("targetSdk", "N/A")}</p>')
            html_parts.append(f'<p><strong>Permissions:</strong> {len(manifest.get("permissions", []))} ta</p>')
            html_parts.append(f'<p><strong>Activities:</strong> {len(manifest.get("activities", []))} ta</p>')
            html_parts.append(f'<p><strong>Services:</strong> {len(manifest.get("services", []))} ta</p>')
            html_parts.append('</div>')

        html_parts.append('</div>')
        html_parts.append('</div>')

        # Resources section
        html_parts.append('<div class="section">')
        html_parts.append('<h2>Resurslar</h2>')
        html_parts.append('<table>')
        html_parts.append('<tr><th>Resurs turi</th><th>Soni</th></tr>')
        html_parts.append(f'<tr><td>Layout fayllar</td><td>{len(resources.get("layouts", {}))}</td></tr>')
        html_parts.append(f'<tr><td>String resurslar</td><td>{len(resources.get("strings", {}))}</td></tr>')
        html_parts.append(f'<tr><td>Drawable fayllar</td><td>{len(resources.get("drawables", []))}</td></tr>')
        html_parts.append('</table>')
        html_parts.append('</div>')

        # Footer
        html_parts.append('<footer>')
        html_parts.append(f'<p>Android Studio Loyiha Tahlilchisi | Yaratilgan: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>')
        html_parts.append('</footer>')

        html_parts.append('</div>')

        # JavaScript
        js_code = """
function searchFiles() {
    var input = document.getElementById('fileSearch');
    var filter = input.value.toLowerCase();
    var table = document.getElementById('filesTable');
    var tr = table.getElementsByTagName('tr');

    for (var i = 1; i < tr.length; i++) {
        var td = tr[i].getElementsByTagName('td')[1];
        if (td) {
            var txtValue = td.textContent || td.innerText;
            if (txtValue.toLowerCase().indexOf(filter) > -1) {
                tr[i].style.display = '';
            } else {
                tr[i].style.display = 'none';
            }
        }
    }
}

function showTab(tabId) {
    var tabs = document.getElementsByClassName('tab');
    for (var i = 0; i < tabs.length; i++) {
        tabs[i].classList.remove('active');
    }

    var contents = document.getElementsByClassName('tab-content');
    for (var i = 0; i < contents.length; i++) {
        contents[i].classList.remove('active');
    }

    event.target.classList.add('active');
    document.getElementById(tabId).classList.add('active');
}
"""

        html_parts.append('<script>')
        html_parts.append(js_code)
        html_parts.append('</script>')

        html_parts.append('</body>')
        html_parts.append('</html>')

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(html_parts))

        return output_path

    def _generate_markdown(self, analyzed_files, modules, resources):
        """Markdown formatida hisobot"""
        output_path = os.path.join(self.output_dir, 'report.md')

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# Android Studio Loyiha Tahlili\n\n")
            f.write(f"**Sana:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            total_files = len(analyzed_files)
            total_lines = sum(f.get('lines', 0) for f in analyzed_files)

            f.write("## Umumiy Statistika\n\n")
            f.write("| Ko'rsatkich | Qiymat |\n")
            f.write("|------------|--------|\n")
            f.write(f"| Jami fayllar | {total_files:,} |\n")
            f.write(f"| Jami qatorlar | {total_lines:,} |\n")
            f.write(f"| Jami hajm | {self._format_size(sum(f.get('size', 0) for f in analyzed_files))} |\n")
            f.write(f"| Modullar | {len(modules)} |\n\n")

            f.write("## Fayl Turlari\n\n")
            f.write("| Kengaytma | Fayllar | Qatorlar |\n")
            f.write("|-----------|---------|----------|\n")

            ext_stats = self._get_file_type_stats(analyzed_files)
            for ext, stats in sorted(ext_stats.items(), key=lambda x: x[1]['count'], reverse=True):
                f.write(f"| {ext} | {stats['count']:,} | {stats['lines']:,} |\n")

            f.write("\n")

            f.write("## TOP 10 Eng Katta Fayllar\n\n")
            sorted_files = sorted(analyzed_files, key=lambda x: x.get('lines', 0), reverse=True)[:10]
            for i, file_info in enumerate(sorted_files, 1):
                f.write(f"{i}. `{file_info.get('relative_path', file_info['path'])}` - "
                       f"{file_info.get('lines', 0):,} qator\n")

            f.write("\n")

            if modules:
                f.write("## Modullar\n\n")
                for module_name, module_info in modules.items():
                    f.write(f"### {module_name}\n\n")
                    f.write(f"- **Fayllar:** {len(module_info['files'])}\n")
                    f.write(f"- **Qatorlar:** {module_info['total_lines']:,}\n")

                    gradle = module_info.get('gradle_info', {})
                    if gradle:
                        f.write(f"- **Application ID:** {gradle.get('application_id', 'N/A')}\n")
                        f.write(f"- **Version:** {gradle.get('version_name', 'N/A')}\n")
                        f.write(f"- **Dependencies:** {len(gradle.get('dependencies', []))} ta\n")

                    f.write("\n")

        return output_path

    def _format_size(self, size_bytes):
        """Hajmni inson o'qiy oladigan formatga o'tkazish"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"

    def _get_file_type_stats(self, analyzed_files):
        """Fayl turlari bo'yicha statistika"""
        stats = defaultdict(lambda: {'count': 0, 'lines': 0})
        for file_info in analyzed_files:
            ext = file_info.get('extension', "Noma'lum")
            stats[ext]['count'] += 1
            stats[ext]['lines'] += file_info.get('lines', 0)
        return dict(stats)

    def _detect_module(self, path):
        """Fayl yo'li asosida modul nomini aniqlash"""
        parts = path.replace('\\\\', '/').split('/')
        for i, part in enumerate(parts):
            if i > 0 and parts[i-1] in ['app', 'feature', 'library', 'core', 'data', 'domain', 'presentation']:
                return parts[i-1]
        if 'app/' in path:
            return 'app'
        if len(parts) > 2:
            return parts[-2]
        return 'root'
