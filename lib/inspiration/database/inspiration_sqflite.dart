import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class InspirationSqflite {
  static final InspirationSqflite _instance =
  InspirationSqflite._internal();
  factory InspirationSqflite() => _instance;
  InspirationSqflite._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'inspiration.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {

        // ── Inspiration categories core table ──────────────
        // No color column — colors are predefined in UI code
        await db.execute('''
          CREATE TABLE inspiration_categories(
            category_id   INTEGER PRIMARY KEY,
            category_icon TEXT
          )
        ''');

        // ── Category translations — one row per language ───
        // en, bn, ar, ur — add more anytime, no schema change
        await db.execute('''
          CREATE TABLE inspiration_category_translations(
            category_id   INTEGER NOT NULL,
            language_code TEXT    NOT NULL,
            title         TEXT    NOT NULL,
            PRIMARY KEY(category_id, language_code),
            FOREIGN KEY(category_id)
              REFERENCES inspiration_categories(category_id)
          )
        ''');

        // ── Inspirations core table ────────────────────────
        // quote_arabic is optional — null for scholar/person quotes
        await db.execute('''
          CREATE TABLE inspirations(
            id            INTEGER PRIMARY KEY,
            category_id   INTEGER NOT NULL,
            is_favorite   INTEGER DEFAULT 0,
            is_bookmarked INTEGER DEFAULT 0,
            FOREIGN KEY(category_id)
              REFERENCES inspiration_categories(category_id)
          )
        ''');

        // ── Inspiration translations ───────────────────────
        // title, quote_text — required
        // reference, author — optional, can be null
        await db.execute('''
          CREATE TABLE inspiration_translations(
            inspiration_id INTEGER NOT NULL,
            language_code  TEXT    NOT NULL,
            title          TEXT,
            quote_text     TEXT,
            reference      TEXT,
            author         TEXT,
            PRIMARY KEY(inspiration_id, language_code),
            FOREIGN KEY(inspiration_id)
              REFERENCES inspirations(id)
          )
        ''');

        // ── Indexes for fast JOIN queries ──────────────────
        await db.execute('''
          CREATE INDEX idx_inspiration_translations
          ON inspiration_translations(inspiration_id, language_code)
        ''');

        await db.execute('''
          CREATE INDEX idx_inspiration_cat_translations
          ON inspiration_category_translations(category_id, language_code)
        ''');

        // ── User interactions ──────────────────────────────
        await db.execute('''
          CREATE TABLE user_inspiration_interactions(
            user_id        TEXT    NOT NULL,
            inspiration_id INTEGER NOT NULL,
            is_favorite    INTEGER DEFAULT 0,
            is_bookmarked  INTEGER DEFAULT 0,
            PRIMARY KEY(user_id, inspiration_id),
            FOREIGN KEY(inspiration_id) REFERENCES inspirations(id)
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_user_inspiration_interactions
          ON user_inspiration_interactions(user_id, inspiration_id)
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // Future language additions — just new rows, no ALTER needed
        // Schema migrations only when adding new core columns
      },
    );
  }

  // ── Categories ──────────────────────────────────────────

  Future<void> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'inspiration_categories',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all categories — COALESCE falls back to English
  Future<List<Map<String, dynamic>>> getAllCategories(
      String languageCode) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        c.category_id,
        c.category_icon,
        COALESCE(t.title, fallback.title, '') AS category_title
      FROM inspiration_categories c
      LEFT JOIN inspiration_category_translations t
        ON c.category_id = t.category_id
        AND t.language_code = ?
      LEFT JOIN inspiration_category_translations fallback
        ON c.category_id = fallback.category_id
        AND fallback.language_code = 'en'
      ORDER BY c.category_id ASC
    ''', [languageCode]);
  }

  // ── Inspirations ────────────────────────────────────────

  Future<void> insertInspiration(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'inspirations',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get inspirations by category — JOIN resolves language
  // COALESCE falls back to English for all translatable fields
  Future<List<Map<String, dynamic>>> getInspirationsByCategory({
    required int categoryId,
    required String languageCode,
    required String userId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        i.id,
        i.category_id,
        COALESCE(t.title,      fb.title,      '') AS title,
        COALESCE(t.quote_text, fb.quote_text, '') AS quote_text,
        COALESCE(t.reference,  fb.reference,  NULL) AS reference,
        COALESCE(t.author,     fb.author,     NULL) AS author,
        COALESCE(
          ui.is_favorite,   i.is_favorite,   0
        ) AS is_favorite,
        COALESCE(
          ui.is_bookmarked, i.is_bookmarked, 0
        ) AS is_bookmarked,
        cat_t.category_title
      FROM inspirations i
      LEFT JOIN inspiration_translations t
        ON i.id = t.inspiration_id
        AND t.language_code = ?
      LEFT JOIN inspiration_translations fb
        ON i.id = fb.inspiration_id
        AND fb.language_code = 'en'
      LEFT JOIN user_inspiration_interactions ui
        ON i.id = ui.inspiration_id
        AND ui.user_id = ?
      LEFT JOIN (
        SELECT
          c2.category_id,
          COALESCE(t2.title, fb2.title, '') AS category_title
        FROM inspiration_categories c2
        LEFT JOIN inspiration_category_translations t2
          ON c2.category_id = t2.category_id
          AND t2.language_code = ?
        LEFT JOIN inspiration_category_translations fb2
          ON c2.category_id = fb2.category_id
          AND fb2.language_code = 'en'
      ) cat_t ON i.category_id = cat_t.category_id
      WHERE i.category_id = ?
      ORDER BY i.id ASC
    ''', [languageCode, userId, languageCode, categoryId]);
  }

  // Get ALL inspirations — same JOIN, no WHERE filter
  Future<List<Map<String, dynamic>>> getAllInspirations({
    required String languageCode,
    required String userId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        i.id,
        i.category_id,
        i.quote_arabic,
        COALESCE(t.title,      fb.title,      '') AS title,
        COALESCE(t.quote_text, fb.quote_text, '') AS quote_text,
        COALESCE(t.reference,  fb.reference,  NULL) AS reference,
        COALESCE(t.author,     fb.author,     NULL) AS author,
        COALESCE(
          ui.is_favorite,   i.is_favorite,   0
        ) AS is_favorite,
        COALESCE(
          ui.is_bookmarked, i.is_bookmarked, 0
        ) AS is_bookmarked,
        cat_t.category_title
      FROM inspirations i
      LEFT JOIN inspiration_translations t
        ON i.id = t.inspiration_id
        AND t.language_code = ?
      LEFT JOIN inspiration_translations fb
        ON i.id = fb.inspiration_id
        AND fb.language_code = 'en'
      LEFT JOIN user_inspiration_interactions ui
        ON i.id = ui.inspiration_id
        AND ui.user_id = ?
      LEFT JOIN (
        SELECT
          c2.category_id,
          COALESCE(t2.title, fb2.title, '') AS category_title
        FROM inspiration_categories c2
        LEFT JOIN inspiration_category_translations t2
          ON c2.category_id = t2.category_id
          AND t2.language_code = ?
        LEFT JOIN inspiration_category_translations fb2
          ON c2.category_id = fb2.category_id
          AND fb2.language_code = 'en'
      ) cat_t ON i.category_id = cat_t.category_id
      ORDER BY i.id ASC
    ''', [languageCode, userId, languageCode]);
  }

  // ── Favorites & Bookmarks ───────────────────────────────

  Future<void> upsertUserInteraction({
    required String userId,
    required int inspirationId,
    required bool isFavorite,
    required bool isBookmarked,
  }) async {
    final db = await database;
    await db.insert(
      'user_inspiration_interactions',
      {
        'user_id':        userId,
        'inspiration_id': inspirationId,
        'is_favorite':    isFavorite ? 1 : 0,
        'is_bookmarked':  isBookmarked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFavoritesForUser({
    required String userId,
    required String languageCode,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        i.id,
        i.category_id,
        i.quote_arabic,
        COALESCE(t.title,      fb.title,      '') AS title,
        COALESCE(t.quote_text, fb.quote_text, '') AS quote_text,
        COALESCE(t.reference,  fb.reference,  NULL) AS reference,
        COALESCE(t.author,     fb.author,     NULL) AS author,
        ui.is_favorite,
        ui.is_bookmarked
      FROM inspirations i
      INNER JOIN user_inspiration_interactions ui
        ON i.id = ui.inspiration_id
        AND ui.user_id = ?
        AND ui.is_favorite = 1
      LEFT JOIN inspiration_translations t
        ON i.id = t.inspiration_id
        AND t.language_code = ?
      LEFT JOIN inspiration_translations fb
        ON i.id = fb.inspiration_id
        AND fb.language_code = 'en'
      ORDER BY i.id ASC
    ''', [userId, languageCode]);
  }

  Future<List<Map<String, dynamic>>> getBookmarkedForUser({
    required String userId,
    required String languageCode,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        i.id,
        i.category_id,
        i.quote_arabic,
        COALESCE(t.title,      fb.title,      '') AS title,
        COALESCE(t.quote_text, fb.quote_text, '') AS quote_text,
        COALESCE(t.reference,  fb.reference,  NULL) AS reference,
        COALESCE(t.author,     fb.author,     NULL) AS author,
        ui.is_favorite,
        ui.is_bookmarked
      FROM inspirations i
      INNER JOIN user_inspiration_interactions ui
        ON i.id = ui.inspiration_id
        AND ui.user_id = ?
        AND ui.is_bookmarked = 1
      LEFT JOIN inspiration_translations t
        ON i.id = t.inspiration_id
        AND t.language_code = ?
      LEFT JOIN inspiration_translations fb
        ON i.id = fb.inspiration_id
        AND fb.language_code = 'en'
      ORDER BY i.id ASC
    ''', [userId, languageCode]);
  }

  Future<void> replaceUserInteractions(
      String userId,
      List<Map<String, dynamic>> interactions,
      ) async {
    if (interactions.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'user_inspiration_interactions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final row in interactions) {
        await txn.insert(
          'user_inspiration_interactions',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getGuestInteractions() async {
    final db = await database;
    return await db.query(
      'user_inspiration_interactions',
      where: 'user_id = ?',
      whereArgs: ['guest'],
    );
  }

  Future<void> migrateGuestToUser(String userId) async {
    final db = await database;
    await db.update(
      'user_inspiration_interactions',
      {'user_id': userId},
      where: 'user_id = ?',
      whereArgs: ['guest'],
    );
  }

  Future<Map<String, dynamic>?> getUserInteractionForInspiration(
      String userId,
      int inspirationId,
      ) async {
    final db = await database;
    final result = await db.query(
      'user_inspiration_interactions',
      where: 'user_id = ? AND inspiration_id = ?',
      whereArgs: [userId, inspirationId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}