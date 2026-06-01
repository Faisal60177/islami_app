import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MasailSqflite {
  static final MasailSqflite _instance = MasailSqflite._internal();
  factory MasailSqflite() => _instance;
  MasailSqflite._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'masail.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {

        // ── Categories core table ──────────────────────────
        await db.execute('''
          CREATE TABLE masail_categories(
            category_id   INTEGER PRIMARY KEY,
            category_icon TEXT
          )
        ''');

        // ── Category translations — one row per language ───
        // Supports: en, bn, ar, ur (add more anytime — no schema change)
        await db.execute('''
          CREATE TABLE masail_category_translations(
            category_id   INTEGER NOT NULL,
            language_code TEXT    NOT NULL,
            title         TEXT    NOT NULL,
            PRIMARY KEY(category_id, language_code),
            FOREIGN KEY(category_id) REFERENCES masail_categories(category_id)
          )
        ''');

        // ── Masail core table — only non-translatable columns here ──
        // arabic is language-independent (always Arabic script)
        await db.execute('''
          CREATE TABLE masail(
            id            INTEGER PRIMARY KEY,
            category_id   INTEGER NOT NULL,
            arabic        TEXT,
            is_bookmarked INTEGER DEFAULT 0,
            FOREIGN KEY(category_id) REFERENCES masail_categories(category_id)
          )
        ''');

        // ── Masail translations — ALL translatable fields here ──────
        // question, answer, reference → required per language row
        // madhab → optional — e.g. "Hanafi" / "حنفي" / "হানাফি" / "حنفی"
        await db.execute('''
          CREATE TABLE masail_translations(
            masail_id     INTEGER NOT NULL,
            language_code TEXT    NOT NULL,
            question      TEXT    NOT NULL,
            answer        TEXT    NOT NULL,
            reference     TEXT    NOT NULL,
            madhab        TEXT,
            PRIMARY KEY(masail_id, language_code),
            FOREIGN KEY(masail_id) REFERENCES masail(id)
          )
        ''');

        // ── Indexes for fast JOIN queries ──────────────────
        await db.execute('''
          CREATE INDEX idx_masail_translations
          ON masail_translations(masail_id, language_code)
        ''');

        await db.execute('''
          CREATE INDEX idx_masail_cat_translations
          ON masail_category_translations(category_id, language_code)
        ''');

        // ── User bookmarks ─────────────────────────────────
        // Separate table so guest bookmarks migrate cleanly to real user
        await db.execute('''
          CREATE TABLE masail_user_bookmarks(
            user_id       TEXT    NOT NULL,
            masail_id     INTEGER NOT NULL,
            is_bookmarked INTEGER DEFAULT 0,
            PRIMARY KEY(user_id, masail_id),
            FOREIGN KEY(masail_id) REFERENCES masail(id)
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // Future language additions — just new rows, no ALTER needed
        // Schema migrations only if adding new columns to core tables
      },
    );
  }

  // ── Categories ──────────────────────────────────────────

  Future<void> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('masail_categories', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertCategoryTranslation({
    required int categoryId,
    required String languageCode,
    required String title,
  }) async {
    final db = await database;
    await db.insert(
      'masail_category_translations',
      {
        'category_id':   categoryId,
        'language_code': languageCode,
        'title':         title,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all categories — resolved language with COALESCE fallback to English
  Future<List<Map<String, dynamic>>> getAllCategories(String languageCode) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        c.category_id,
        c.category_icon,
        COALESCE(t.title, fallback.title, '') AS category_title
      FROM masail_categories c
      LEFT JOIN masail_category_translations t
        ON c.category_id = t.category_id AND t.language_code = ?
      LEFT JOIN masail_category_translations fallback
        ON c.category_id = fallback.category_id AND fallback.language_code = 'en'
      ORDER BY c.category_id ASC
    ''', [languageCode]);
  }

  // ── Masail ──────────────────────────────────────────────

  Future<void> insertMasail(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('masail', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertMasailTranslation({
    required int masailId,
    required String languageCode,
    required String question,
    required String answer,
    required String reference,
    String? madhab,           // optional — not every masail has a madhab
  }) async {
    final db = await database;
    await db.insert(
      'masail_translations',
      {
        'masail_id':     masailId,
        'language_code': languageCode,
        'question':      question,
        'answer':        answer,
        'reference':     reference,
        'madhab':        madhab,   // nullable — fine if null
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get masail by category — JOIN resolves language, COALESCE falls back to English
  Future<List<Map<String, dynamic>>> getMasailByCategory({
    required int categoryId,
    required String languageCode,
    required String userId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        m.id,
        m.category_id,
        m.arabic,
        COALESCE(t.question,   fb.question,   '') AS question,
        COALESCE(t.answer,     fb.answer,     '') AS answer,
        COALESCE(t.reference,  fb.reference,  '') AS reference,
        COALESCE(t.madhab,     fb.madhab,     NULL) AS madhab,
        COALESCE(ub.is_bookmarked, m.is_bookmarked, 0) AS is_bookmarked,
        cat_t.category_title
      FROM masail m
      LEFT JOIN masail_translations t
        ON m.id = t.masail_id AND t.language_code = ?
      LEFT JOIN masail_translations fb
        ON m.id = fb.masail_id AND fb.language_code = 'en'
      LEFT JOIN masail_user_bookmarks ub
        ON m.id = ub.masail_id AND ub.user_id = ?
      LEFT JOIN (
        SELECT
          c2.category_id,
          COALESCE(t2.title, fb2.title, '') AS category_title
        FROM masail_categories c2
        LEFT JOIN masail_category_translations t2
          ON c2.category_id = t2.category_id AND t2.language_code = ?
        LEFT JOIN masail_category_translations fb2
          ON c2.category_id = fb2.category_id AND fb2.language_code = 'en'
      ) cat_t ON m.category_id = cat_t.category_id
      WHERE m.category_id = ?
      ORDER BY m.id ASC
    ''', [languageCode, userId, languageCode, categoryId]);
  }

  // Get ALL masail — same JOIN logic but no WHERE filter
  Future<List<Map<String, dynamic>>> getAllMasail({
    required String languageCode,
    required String userId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        m.id,
        m.category_id,
        m.arabic,
        COALESCE(t.question,   fb.question,   '') AS question,
        COALESCE(t.answer,     fb.answer,     '') AS answer,
        COALESCE(t.reference,  fb.reference,  '') AS reference,
        COALESCE(t.madhab,     fb.madhab,     NULL) AS madhab,
        COALESCE(ub.is_bookmarked, m.is_bookmarked, 0) AS is_bookmarked,
        cat_t.category_title
      FROM masail m
      LEFT JOIN masail_translations t
        ON m.id = t.masail_id AND t.language_code = ?
      LEFT JOIN masail_translations fb
        ON m.id = fb.masail_id AND fb.language_code = 'en'
      LEFT JOIN masail_user_bookmarks ub
        ON m.id = ub.masail_id AND ub.user_id = ?
      LEFT JOIN (
        SELECT
          c2.category_id,
          COALESCE(t2.title, fb2.title, '') AS category_title
        FROM masail_categories c2
        LEFT JOIN masail_category_translations t2
          ON c2.category_id = t2.category_id AND t2.language_code = ?
        LEFT JOIN masail_category_translations fb2
          ON c2.category_id = fb2.category_id AND fb2.language_code = 'en'
      ) cat_t ON m.category_id = cat_t.category_id
      ORDER BY m.id ASC
    ''', [languageCode, userId, languageCode]);
  }

  // ── Bookmarks ───────────────────────────────────────────

  Future<void> upsertUserBookmark({
    required String userId,
    required int masailId,
    required bool isBookmarked,
  }) async {
    final db = await database;
    await db.insert(
      'masail_user_bookmarks',
      {
        'user_id':       userId,
        'masail_id':     masailId,
        'is_bookmarked': isBookmarked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBookmarkedForUser({
    required String userId,
    required String languageCode,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        m.id,
        m.category_id,
        m.arabic,
        COALESCE(t.question,   fb.question,   '') AS question,
        COALESCE(t.answer,     fb.answer,     '') AS answer,
        COALESCE(t.reference,  fb.reference,  '') AS reference,
        COALESCE(t.madhab,     fb.madhab,     NULL) AS madhab,
        ub.is_bookmarked
      FROM masail m
      INNER JOIN masail_user_bookmarks ub
        ON m.id = ub.masail_id AND ub.user_id = ? AND ub.is_bookmarked = 1
      LEFT JOIN masail_translations t
        ON m.id = t.masail_id AND t.language_code = ?
      LEFT JOIN masail_translations fb
        ON m.id = fb.masail_id AND fb.language_code = 'en'
      ORDER BY m.id ASC
    ''', [userId, languageCode]);
  }

  Future<void> replaceUserBookmarks(
      String userId, List<Map<String, dynamic>> bookmarks) async {
    if (bookmarks.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('masail_user_bookmarks',
          where: 'user_id = ?', whereArgs: [userId]);
      for (final row in bookmarks) {
        await txn.insert('masail_user_bookmarks', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getGuestBookmarks() async {
    final db = await database;
    return await db.query('masail_user_bookmarks',
        where: 'user_id = ?', whereArgs: ['guest']);
  }

  Future<void> migrateGuestToUser(String userId) async {
    final db = await database;
    await db.update('masail_user_bookmarks', {'user_id': userId},
        where: 'user_id = ?', whereArgs: ['guest']);
  }

  Future<Map<String, dynamic>?> getUserBookmarkForMasail(
      String userId, int masailId) async {
    final db = await database;
    final result = await db.query('masail_user_bookmarks',
        where: 'user_id = ? AND masail_id = ?',
        whereArgs: [userId, masailId],
        limit: 1);
    return result.isNotEmpty ? result.first : null;
  }
}