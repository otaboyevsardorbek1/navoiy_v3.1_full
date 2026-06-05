// lib/core/sync/sync_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../utils/settings_service.dart';
import '../network/auth_service.dart';
import '../../data/datasources/local/database_helper.dart';

/// Offline/Online sinxronizatsiya boshqaruvchisi
class SyncManager {
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager._();
  SyncManager._();

  final _dio = Dio();

  // ─── Paths ────────────────────────────────────────────────────────────────

  Future<Directory> get _contentDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/content');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _asarFile(String slug) async {
    final dir = await _contentDir;
    return File('${dir.path}/asarlar/$slug.json');
  }

  Future<File> _sherlarFile() async {
    final dir = await _contentDir;
    return File('${dir.path}/sherlar.json');
  }

  Future<void> _ensureAsarDir() async {
    final dir = await _contentDir;
    final asarDir = Directory('${dir.path}/asarlar');
    if (!await asarDir.exists()) await asarDir.create(recursive: true);
  }

  // ─── Version tracking ─────────────────────────────────────────────────────

  Future<Map<String, int>> _getLocalVersions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.syncVersionsKey) ?? '{}';
    return Map<String, int>.from(jsonDecode(json));
  }

  Future<void> _saveLocalVersion(String slug, int version) async {
    final prefs = await SharedPreferences.getInstance();
    final versions = await _getLocalVersions();
    versions[slug] = version;
    await prefs.setString(AppConstants.syncVersionsKey, jsonEncode(versions));
  }

  Future<int> getLocalVersion(String slug) async {
    final versions = await _getLocalVersions();
    return versions[slug] ?? 0;
  }

  // ─── Checksum verification ────────────────────────────────────────────────

  String _computeChecksum(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  bool _verifyChecksum(String content, String expectedChecksum) {
    if (expectedChecksum.isEmpty) return true;
    return _computeChecksum(content) == expectedChecksum;
  }

  // ─── Auth Header ──────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String get _baseUrl => SettingsService.instance.apiBaseUrl;

  // ─── Sync Manifest ────────────────────────────────────────────────────────

  Future<SyncManifest?> fetchManifest() async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/sync/manifest',
        options: Options(headers: await _authHeaders()),
      );
      return SyncManifest.fromJson(resp.data);
    } catch (e) {
      return null;
    }
  }

  // ─── Download Asar JSON ───────────────────────────────────────────────────

  Future<bool> downloadAsar(String slug, {int? expectedVersion, String? expectedChecksum}) async {
    try {
      await _ensureAsarDir();
      final resp = await _dio.get(
        '$_baseUrl/sync/download/asar/$slug',
        options: Options(
          headers: await _authHeaders(),
          responseType: ResponseType.plain,
        ),
      );

      final content = resp.data as String;

      // Checksum tekshirish
      if (expectedChecksum != null && expectedChecksum.isNotEmpty) {
        if (!_verifyChecksum(content, expectedChecksum)) {
          return false;
        }
      }

      // Faylga saqlash
      final file = await _asarFile(slug);
      await file.writeAsString(content, encoding: utf8);

      // Versiyani saqlash
      final version = int.tryParse(resp.headers.value('x-content-version') ?? '') ?? (expectedVersion ?? 1);
      await _saveLocalVersion(slug, version);

      // SQLite ga meta ma'lumot saqlash
      await DatabaseHelper.instance.upsertAsarMeta(slug: slug, version: version);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Download all Sherlar ─────────────────────────────────────────────────

  Future<bool> downloadSherlar() async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/sync/download/sherlar',
        options: Options(
          headers: await _authHeaders(),
          responseType: ResponseType.plain,
        ),
      );
      final content = resp.data as String;
      final file = await _sherlarFile();
      await file.writeAsString(content, encoding: utf8);

      // SQLite ga she'rlar meta saqlash
      final data = jsonDecode(content);
      final sherlar = data['sherlar'] as List;
      for (final sher in sherlar) {
        await DatabaseHelper.instance.upsertSherFromJson(sher as Map<String, dynamic>);
      }

      await _saveLocalVersion('sherlar_bundle', data['version'] ?? 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Full sync ────────────────────────────────────────────────────────────

  Future<SyncResult> performFullSync({
    void Function(SyncProgress progress)? onProgress,
  }) async {
    final manifest = await fetchManifest();
    if (manifest == null) {
      return SyncResult(success: false, error: 'Manifest yuklab bo\'lmadi');
    }

    int downloaded = 0;
    int failed = 0;
    int skipped = 0;
    final total = manifest.asarlar.length + 1; // +1 for sherlar bundle

    // Asarlar
    for (int i = 0; i < manifest.asarlar.length; i++) {
      final item = manifest.asarlar[i];
      final localVersion = await getLocalVersion(item.slug);

      onProgress?.call(SyncProgress(
        current: i + 1,
        total: total,
        currentItem: item.slug,
        phase: 'Asarlar yuklanmoqda...',
      ));

      if (localVersion >= item.version) {
        skipped++;
        continue;
      }

      final ok = await downloadAsar(
        item.slug,
        expectedVersion: item.version,
        expectedChecksum: item.checksum,
      );
      if (ok) {
        downloaded++;
      } else {
        failed++;
      }
    }

    // Sherlar bundle
    onProgress?.call(SyncProgress(
      current: total,
      total: total,
      currentItem: 'sherlar',
      phase: 'She\'rlar yuklanmoqda...',
    ));
    final sherlarLocalVersion = await getLocalVersion('sherlar_bundle');
    if (sherlarLocalVersion < manifest.bundleVersion) {
      final ok = await downloadSherlar();
      if (ok) downloaded++;
      else failed++;
    } else {
      skipped++;
    }

    // Progress serverga yuborish
    await syncProgressToServer();

    return SyncResult(
      success: failed == 0,
      downloaded: downloaded,
      skipped: skipped,
      failed: failed,
    );
  }

  // ─── Delta sync (faqat yangilanganlarni) ─────────────────────────────────

  Future<SyncResult> performDeltaSync() async {
    try {
      final localVersions = await _getLocalVersions();
      final resp = await _dio.post(
        '$_baseUrl/sync/check',
        data: {'local_versions': localVersions},
        options: Options(headers: await _authHeaders()),
      );

      final needsUpdate = resp.data['needs_update'] as List;
      if (needsUpdate.isEmpty) {
        return SyncResult(success: true, downloaded: 0, skipped: localVersions.length);
      }

      int downloaded = 0;
      int failed = 0;
      for (final item in needsUpdate) {
        final slug = item['slug'] as String;
        final version = item['version'] as int;
        final checksum = item['checksum'] as String? ?? '';
        final ok = await downloadAsar(slug, expectedVersion: version, expectedChecksum: checksum);
        if (ok) downloaded++;
        else failed++;
      }

      return SyncResult(success: failed == 0, downloaded: downloaded, failed: failed);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  // ─── Read progress sync ───────────────────────────────────────────────────

  Future<void> syncProgressToServer() async {
    try {
      // Local progress larni serverga yuborish
      final progressList = await DatabaseHelper.instance.getAllProgress();
      for (final p in progressList) {
        if (!p.isSynced) {
          await _dio.post(
            '$_baseUrl/sync/progress',
            data: {
              'asar_id': p.asarId,
              'current_page': p.currentPage,
              'scroll_offset': p.scrollOffset,
              'is_completed': p.isCompleted,
            },
            options: Options(headers: await _authHeaders()),
          );
          await DatabaseHelper.instance.markProgressSynced(p.asarId);
        }
      }
    } catch (_) {
      // Offline holatda xato bo'lishi normal
    }
  }

  Future<void> fetchProgressFromServer() async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/sync/progress',
        options: Options(headers: await _authHeaders()),
      );
      final list = resp.data as List;
      for (final p in list) {
        await DatabaseHelper.instance.upsertProgress(
          asarId: p['asar_id'],
          currentPage: p['current_page'],
          scrollOffset: (p['scroll_offset'] as num).toDouble(),
          isCompleted: p['is_completed'] ?? false,
          isSynced: true,
        );
      }
    } catch (_) {}
  }

  // ─── Read asar from file ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> readAsarContent(String slug) async {
    try {
      final file = await _asarFile(slug);
      if (!await file.exists()) return null;
      final content = await file.readAsString(encoding: utf8);
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> readAsarPage(String slug, int pageNumber) async {
    final content = await readAsarContent(slug);
    if (content == null) return null;
    final pages = content['pages'] as List? ?? [];
    for (final page in pages) {
      if ((page['page_number'] as int?) == pageNumber) {
        return page as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> readSherlarBundle() async {
    try {
      final file = await _sherlarFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString(encoding: utf8);
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasAsarContent(String slug) async {
    final file = await _asarFile(slug);
    return await file.exists();
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────────

class SyncManifest {
  final int bundleVersion;
  final DateTime generatedAt;
  final List<SyncItem> asarlar;
  final List<SyncItem> sherlar;

  SyncManifest({
    required this.bundleVersion,
    required this.generatedAt,
    required this.asarlar,
    required this.sherlar,
  });

  factory SyncManifest.fromJson(Map<String, dynamic> j) => SyncManifest(
        bundleVersion: j['bundle_version'] ?? 1,
        generatedAt: DateTime.tryParse(j['generated_at'] ?? '') ?? DateTime.now(),
        asarlar: (j['asarlar'] as List? ?? []).map((e) => SyncItem.fromJson(e)).toList(),
        sherlar: (j['sherlar'] as List? ?? []).map((e) => SyncItem.fromJson(e)).toList(),
      );
}

class SyncItem {
  final int id;
  final String slug;
  final String contentType;
  final int version;
  final String checksum;
  final int fileSizeBytes;

  SyncItem({
    required this.id,
    required this.slug,
    required this.contentType,
    required this.version,
    required this.checksum,
    required this.fileSizeBytes,
  });

  factory SyncItem.fromJson(Map<String, dynamic> j) => SyncItem(
        id: j['id'] ?? 0,
        slug: j['slug'] ?? '',
        contentType: j['content_type'] ?? 'asar',
        version: j['version'] ?? 1,
        checksum: j['checksum'] ?? '',
        fileSizeBytes: j['file_size_bytes'] ?? 0,
      );
}

class SyncResult {
  final bool success;
  final int downloaded;
  final int skipped;
  final int failed;
  final String? error;

  SyncResult({
    required this.success,
    this.downloaded = 0,
    this.skipped = 0,
    this.failed = 0,
    this.error,
  });
}

class SyncProgress {
  final int current;
  final int total;
  final String currentItem;
  final String phase;

  SyncProgress({
    required this.current,
    required this.total,
    required this.currentItem,
    required this.phase,
  });

  double get fraction => total == 0 ? 0 : current / total;
}
