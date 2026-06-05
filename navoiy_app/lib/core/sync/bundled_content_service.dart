// lib/core/sync/bundled_content_service.dart
// Assets ichidagi default ma'lumotlarni boshqaradi
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../../data/datasources/local/database_helper.dart';

class BundledContentService {
  static BundledContentService? _instance;
  static BundledContentService get instance =>
      _instance ??= BundledContentService._();
  BundledContentService._();

  bool _initialized = false;

  /// Birinchi ishga tushishda assets/data/ dan
  /// ilovaning ichki xotirasiga ko'chiradi
  Future<void> initializeIfNeeded() async {
    if (_initialized) return;

    final prefs_key = AppConstants.bundleInitializedKey;
    final db = DatabaseHelper.instance;
    final isInit = await db.getSyncMeta(prefs_key);

    if (isInit == '1') {
      _initialized = true;
      return;
    }

    await _extractBundledContent();
    await db.setSyncMeta(prefs_key, '1');
    _initialized = true;
  }

  Future<void> _extractBundledContent() async {
    final appDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${appDir.path}/content');
    final asarDir = Directory('${contentDir.path}/asarlar');
    await asarDir.create(recursive: true);

    // manifest.json o'qish
    final manifestStr = await rootBundle.loadString('assets/data/manifest.json');
    final manifest = jsonDecode(manifestStr) as Map<String, dynamic>;
    final asarlar = manifest['asarlar'] as List;

    int copied = 0;
    for (final meta in asarlar) {
      final slug = meta['slug'] as String;
      final targetFile = File('${asarDir.path}/$slug.json');

      // Agar avval ko'chirilgan bo'lsa va versiya to'g'ri bo'lsa — o'tkazib yuborish
      if (await targetFile.exists()) {
        // Versiyani tekshirish
        final localVersion = await DatabaseHelper.instance.getProgress(meta['id'] as int);
        if (localVersion != null) {
          copied++;
          continue;
        }
      }

      // Assets dan ko'chirish
      try {
        final assetPath = 'assets/data/asarlar/$slug.json';
        final bytes = await rootBundle.load(assetPath);
        await targetFile.writeAsBytes(bytes.buffer.asUint8List());

        // DB meta yangilash
        await DatabaseHelper.instance.upsertAsarMeta(
          slug: slug,
          version: meta['version'] as int? ?? 1,
          totalPages: meta['total_pages'] as int?,
          checksum: meta['checksum'] as String?,
        );
        copied++;
      } catch (e) {
        // Asset mavjud emas — keyinroq onlinedan yuklanadi
      }
    }

    // sherlar.json ko'chirish
    try {
      final sherlarStr = await rootBundle.loadString('assets/data/sherlar.json');
      final sherlarData = jsonDecode(sherlarStr) as Map<String, dynamic>;
      final sherlar = sherlarData['sherlar'] as List;
      for (final s in sherlar) {
        await DatabaseHelper.instance.upsertSherFromJson(s as Map<String, dynamic>);
      }
      final sherFile = File('${contentDir.path}/sherlar.json');
      await sherFile.writeAsString(sherlarStr, encoding: utf8);
    } catch (_) {}

    // quizlar.json ko'chirish va DB ga saqlash
    try {
      final quizStr = await rootBundle.loadString('assets/data/quizlar.json');
      final quizFile = File('${contentDir.path}/quizlar.json');
      await quizFile.writeAsString(quizStr, encoding: utf8);
      // DB ga quizlar ham saqlanadi (kelajakda)
    } catch (_) {}
  }

  /// Manifest o'qish
  Future<Map<String, dynamic>?> readManifest() async {
    try {
      final str = await rootBundle.loadString('assets/data/manifest.json');
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Asar metalarini assets manifest dan olish (offline default)
  Future<List<Map<String, dynamic>>> getDefaultAsarlarMeta() async {
    final manifest = await readManifest();
    if (manifest == null) return [];
    return List<Map<String, dynamic>>.from(manifest['asarlar'] as List);
  }

  /// Bitta asar JSON ni o'qish (assets dan)
  Future<Map<String, dynamic>?> readAsarFromAssets(String slug) async {
    try {
      final str = await rootBundle.loadString('assets/data/asarlar/$slug.json');
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// O'chirish — faqat ko'chirilgan faylni o'chiradi (asset o'chmaydi)
  Future<bool> deleteAsarContent(String slug) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/content/asarlar/$slug.json');
      if (await file.exists()) {
        await file.delete();
        await DatabaseHelper.instance.upsertAsarMeta(
          slug: slug, version: 0,
          totalPages: null, checksum: null,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Barcha asarlar hajmini hisoblash
  Future<Map<String, int>> getStorageUsage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${appDir.path}/content');
    final usage = <String, int>{};

    if (!await contentDir.exists()) return usage;

    await for (final entity in contentDir.list(recursive: true)) {
      if (entity is File) {
        final name = entity.path.split('/').last.replaceAll('.json', '');
        usage[name] = await entity.length();
      }
    }
    return usage;
  }
}
