// lib/data/datasources/local/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/models.dart';
import '../../../core/constants/app_constants.dart';

class ReadProgressLocal {
  final int asarId;
  final int currentPage;
  final int totalPages;
  final double scrollOffset;
  final bool isCompleted;
  final bool isSynced;
  final String? lastReadAt;

  ReadProgressLocal({
    required this.asarId,
    required this.currentPage,
    required this.totalPages,
    required this.scrollOffset,
    required this.isCompleted,
    required this.isSynced,
    this.lastReadAt,
  });

  factory ReadProgressLocal.fromMap(Map<String, dynamic> m) => ReadProgressLocal(
        asarId: m['asar_id'] as int,
        currentPage: m['current_page'] as int,
        totalPages: m['total_pages'] as int,
        scrollOffset: (m['scroll_offset'] as num).toDouble(),
        isCompleted: (m['is_completed'] as int) == 1,
        isSynced: (m['is_synced'] as int) == 1,
        lastReadAt: m['last_read_at'] as String?,
      );
}

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;
  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE asarlar (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        title         TEXT NOT NULL,
        title_uz      TEXT NOT NULL,
        slug          TEXT UNIQUE NOT NULL,
        description   TEXT,
        category      TEXT NOT NULL,
        image_url     TEXT,
        year          INTEGER,
        language      TEXT DEFAULT 'uz',
        is_favorite   INTEGER DEFAULT 0,
        read_count    INTEGER DEFAULT 0,
        tags          TEXT DEFAULT '[]',
        total_pages   INTEGER DEFAULT 1,
        version       INTEGER DEFAULT 0,
        checksum      TEXT,
        is_downloaded INTEGER DEFAULT 0,
        created_at    TEXT,
        updated_at    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sherlar (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT NOT NULL,
        slug        TEXT UNIQUE NOT NULL,
        content     TEXT NOT NULL,
        type        TEXT NOT NULL,
        description TEXT,
        asar_id     INTEGER,
        asar_title  TEXT,
        is_favorite INTEGER DEFAULT 0,
        like_count  INTEGER DEFAULT 0,
        audio_url   TEXT,
        version     INTEGER DEFAULT 1,
        created_at  TEXT,
        updated_at  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE read_progress (
        asar_id       INTEGER PRIMARY KEY,
        current_page  INTEGER DEFAULT 1,
        total_pages   INTEGER DEFAULT 1,
        scroll_offset REAL DEFAULT 0.0,
        is_completed  INTEGER DEFAULT 0,
        is_synced     INTEGER DEFAULT 0,
        last_read_at  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_results_local (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id          INTEGER NOT NULL,
        asar_id          INTEGER NOT NULL,
        page_number      INTEGER NOT NULL,
        selected_answers TEXT NOT NULL,
        is_correct       INTEGER NOT NULL,
        points_earned    INTEGER DEFAULT 0,
        time_spent_sec   INTEGER DEFAULT 0,
        is_synced        INTEGER DEFAULT 0,
        answered_at      TEXT
      )
    ''');

    await _insertSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final sql in [
        'ALTER TABLE asarlar ADD COLUMN slug TEXT',
        'ALTER TABLE asarlar ADD COLUMN total_pages INTEGER DEFAULT 1',
        'ALTER TABLE asarlar ADD COLUMN version INTEGER DEFAULT 0',
        'ALTER TABLE asarlar ADD COLUMN checksum TEXT',
        'ALTER TABLE asarlar ADD COLUMN is_downloaded INTEGER DEFAULT 0',
        'ALTER TABLE asarlar ADD COLUMN updated_at TEXT',
        'ALTER TABLE sherlar ADD COLUMN slug TEXT',
        'ALTER TABLE sherlar ADD COLUMN version INTEGER DEFAULT 1',
        'ALTER TABLE sherlar ADD COLUMN updated_at TEXT',
      ]) {
        try { await db.execute(sql); } catch (_) {}
      }
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS read_progress (
          asar_id INTEGER PRIMARY KEY, current_page INTEGER DEFAULT 1,
          total_pages INTEGER DEFAULT 1, scroll_offset REAL DEFAULT 0.0,
          is_completed INTEGER DEFAULT 0, is_synced INTEGER DEFAULT 0, last_read_at TEXT)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS sync_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS quiz_results_local (
          id INTEGER PRIMARY KEY AUTOINCREMENT, quiz_id INTEGER NOT NULL,
          asar_id INTEGER NOT NULL, page_number INTEGER NOT NULL,
          selected_answers TEXT NOT NULL, is_correct INTEGER NOT NULL,
          points_earned INTEGER DEFAULT 0, time_spent_sec INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0, answered_at TEXT)''');
      } catch (_) {}
    }
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final asarlar = [
      {'title':'Xamsa','title_uz':'Xamsa','slug':'xamsa','description':'Alisher Navoiyning besh dostondan iborat buyuk asari','category':'doston','year':1483,'tags':'["doston","klassik","xamsa"]','total_pages':2,'version':0,'is_favorite':0,'read_count':0,'is_downloaded':0,'created_at':now},
      {'title':'Farhod va Shirin','title_uz':'Farhod va Shirin','slug':'farhod-va-shirin','description':'Muhabbat va sadoqat haqidagi buyuk doston','category':'doston','year':1484,'tags':'["doston","muhabbat","xamsa"]','total_pages':2,'version':0,'is_favorite':0,'read_count':0,'is_downloaded':0,'created_at':now},
      {'title':'Layli va Majnun','title_uz':'Layli va Majnun','slug':'layli-va-majnun','description':'Ishq va iztirob haqidagi sehrli doston','category':'doston','year':1484,'tags':'["doston","ishq","xamsa"]','total_pages':2,'version':0,'is_favorite':0,'read_count':0,'is_downloaded':0,'created_at':now},
      {'title':'Hayrat ul-abror','title_uz':'Hayrat ul-abror','slug':'hayrat-ul-abror','description':'Xamsa\'ning birinchi dostoni','category':'doston','year':1483,'tags':'["doston","axloq"]','total_pages':1,'version':0,'is_favorite':0,'read_count':0,'is_downloaded':0,'created_at':now},
      {'title':'Muhokamatul-lug\'atayn','title_uz':'Muhokamatul-lug\'atayn','slug':'muhokamatul-lugatayn','description':'Ikki tilning muqoyasasi','category':'ilmiy','year':1499,'tags':'["til","ilm"]','total_pages':1,'version':0,'is_favorite':0,'read_count':0,'is_downloaded':0,'created_at':now},
    ];
    for (final a in asarlar) {
      await db.insert('asarlar', a, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final sherlar = [
      {'title':"Ko'ngul mulki",'slug':'kongul-mulki','type':'gazal','content':"Ko'ngul mulkida sulton bo'lsa ishq,\nNechuk ta'rif etsam, ne bo'lsa farq?\nKo'z — dengizi ul mulkning, ko'ngl — bar,\nKo'rib bo'lmas ul daryoni zevar.",'description':"Ko'ngul va ishq haqida g'azal",'is_favorite':0,'like_count':145,'version':1,'created_at':now},
      {'title':'Ilm madhi','slug':'ilm-madhi','type':'ruboiy','content':"Ilm ahlini aziz tutkim, ilm aziz,\nIlmsiz kishini bilgil sen kamsiz.\nKim ilm o'rganar, ul inson bo'lur,\nIlmsiz yurgan — inson emas, mol bo'lur.",'description':"Ilm va ma'rifat haqida ruboiy",'is_favorite':0,'like_count':289,'version':1,'created_at':now},
      {'title':'Vatan sevgisi','slug':'vatan-sevgisi','type':'qita','content':"Vatandir kishiga jannatdan aziz,\nVatansiz yashagan har dam bo'lur qiz.",'description':"Vatan sevgisini ulug'lovchi she'r",'is_favorite':0,'like_count':312,'version':1,'created_at':now},
      {'title':'Hikmat: Kishi qadri','slug':'hikmat-kishi-qadri','type':'hikmat','content':"Kishi qadrin bilur eding bir kun,\nAmmo ketsa, bilinur qadr tamom.",'description':"Inson qadri haqida hikmat",'is_favorite':0,'like_count':421,'version':1,'created_at':now},
      {'title':"Do'stlik haqida",'slug':'dostlik-haqida','type':'ruboiy','content':"Do'st ul erur kim, qilgay dard qo'shib,\nYolg'iz qo'ymas, bir umr yonib.",'description':"Haqiqiy do'stlik haqida",'is_favorite':0,'like_count':178,'version':1,'created_at':now},
    ];
    for (final s in sherlar) {
      await db.insert('sherlar', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ─── Asarlar ──────────────────────────────────────────────────────────────

  Future<List<AsarModel>> getAsarlar({String? category, String? search, int? limit, int? offset}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (category != null && category.isNotEmpty) { where += ' AND category = ?'; args.add(category); }
    if (search != null && search.isNotEmpty) { where += ' AND (title_uz LIKE ? OR description LIKE ?)'; args.addAll(['%$search%','%$search%']); }
    final rows = await db.query('asarlar', where: where, whereArgs: args.isEmpty ? null : args, limit: limit, offset: offset, orderBy: 'id ASC');
    return rows.map(_asarFromRow).toList();
  }

  Future<AsarModel?> getAsarById(int id) async {
    final db = await database;
    final rows = await db.query('asarlar', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _asarFromRow(rows.first);
  }

  Future<AsarModel?> getAsarBySlug(String slug) async {
    final db = await database;
    final rows = await db.query('asarlar', where: 'slug = ?', whereArgs: [slug]);
    return rows.isEmpty ? null : _asarFromRow(rows.first);
  }

  Future<void> upsertAsarMeta({required String slug, required int version, int? totalPages, String? checksum}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{'version': version, 'is_downloaded': 1, 'updated_at': now};
    if (totalPages != null) updates['total_pages'] = totalPages;
    if (checksum != null) updates['checksum'] = checksum;
    await db.update('asarlar', updates, where: 'slug = ?', whereArgs: [slug]);
  }

  Future<void> toggleAsarFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update('asarlar', {'is_favorite': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementReadCount(int id) async {
    final db = await database;
    await db.rawUpdate('UPDATE asarlar SET read_count = read_count + 1 WHERE id = ?', [id]);
  }

  // ─── Sherlar ──────────────────────────────────────────────────────────────

  Future<List<SherModel>> getSherlar({String? type, String? search, int? asarId, int? limit, int? offset}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (type != null && type.isNotEmpty) { where += ' AND type = ?'; args.add(type); }
    if (asarId != null) { where += ' AND asar_id = ?'; args.add(asarId); }
    if (search != null && search.isNotEmpty) { where += ' AND (title LIKE ? OR content LIKE ?)'; args.addAll(['%$search%','%$search%']); }
    final rows = await db.query('sherlar', where: where, whereArgs: args.isEmpty ? null : args, limit: limit, offset: offset, orderBy: 'id ASC');
    return rows.map(_sherFromRow).toList();
  }

  Future<void> upsertSherFromJson(Map<String, dynamic> j) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('sherlar', {
      'title': j['title'] ?? '', 'slug': j['slug'] ?? '',
      'content': j['content'] ?? '', 'type': j['type'] ?? 'gazal',
      'description': j['description'], 'asar_id': j['asar_id'],
      'like_count': j['like_count'] ?? 0, 'audio_url': j['audio_url'],
      'version': j['version'] ?? 1, 'is_favorite': 0,
      'updated_at': j['updated_at'] ?? now, 'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> toggleSherFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update('sherlar', {'is_favorite': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Read Progress ─────────────────────────────────────────────────────────

  Future<void> upsertProgress({required int asarId, required int currentPage, required double scrollOffset, required bool isCompleted, bool isSynced = false, int? totalPages}) async {
    final db = await database;
    int pages = totalPages ?? 1;
    if (totalPages == null) {
      final rows = await db.query('asarlar', columns: ['total_pages'], where: 'id = ?', whereArgs: [asarId]);
      if (rows.isNotEmpty) pages = (rows.first['total_pages'] as int?) ?? 1;
    }
    await db.insert('read_progress', {
      'asar_id': asarId, 'current_page': currentPage, 'total_pages': pages,
      'scroll_offset': scrollOffset, 'is_completed': isCompleted ? 1 : 0,
      'is_synced': isSynced ? 1 : 0, 'last_read_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReadProgressLocal?> getProgress(int asarId) async {
    final db = await database;
    final rows = await db.query('read_progress', where: 'asar_id = ?', whereArgs: [asarId]);
    return rows.isEmpty ? null : ReadProgressLocal.fromMap(rows.first);
  }

  Future<List<ReadProgressLocal>> getAllProgress() async {
    final db = await database;
    final rows = await db.query('read_progress');
    return rows.map(ReadProgressLocal.fromMap).toList();
  }

  Future<void> markProgressSynced(int asarId) async {
    final db = await database;
    await db.update('read_progress', {'is_synced': 1}, where: 'asar_id = ?', whereArgs: [asarId]);
  }

  // ─── Quiz results ──────────────────────────────────────────────────────────

  Future<void> saveQuizResult({required int quizId, required int asarId, required int pageNumber, required List<int> selectedAnswers, required bool isCorrect, required int pointsEarned, int timeSpentSec = 0}) async {
    final db = await database;
    await db.insert('quiz_results_local', {
      'quiz_id': quizId, 'asar_id': asarId, 'page_number': pageNumber,
      'selected_answers': selectedAnswers.join(','), 'is_correct': isCorrect ? 1 : 0,
      'points_earned': pointsEarned, 'time_spent_sec': timeSpentSec,
      'is_synced': 0, 'answered_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Sync meta ─────────────────────────────────────────────────────────────

  Future<void> setSyncMeta(String key, String value) async {
    final db = await database;
    await db.insert('sync_meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSyncMeta(String key) async {
    final db = await database;
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  AsarModel _asarFromRow(Map<String, dynamic> r) => AsarModel.fromJson({
    ...r,
    'tags': _parseTags(r['tags'] as String?),
    'is_favorite': (r['is_favorite'] as int?) == 1,
    'is_downloaded': (r['is_downloaded'] as int?) == 1,
    'total_pages': r['total_pages'] ?? 1,
    'version': r['version'] ?? 0,
  });

  SherModel _sherFromRow(Map<String, dynamic> r) => SherModel.fromJson({
    ...r, 'is_favorite': (r['is_favorite'] as int?) == 1,
  });

  List<dynamic> _parseTags(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final clean = raw.replaceAll('[','').replaceAll(']','').replaceAll('"','');
      return clean.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) { return []; }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }
}
