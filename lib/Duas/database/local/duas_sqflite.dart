import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DuasSqflite {
  static final DuasSqflite _instance = DuasSqflite._internal();
  factory DuasSqflite() => _instance;
  DuasSqflite._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<void> initFromAssetIfNeeded() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'duas.db');

    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      final data  = await rootBundle.load('assets/db/duas.db');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint('✅ duas.db copied from assets');
    }

    // ✅ Always initialize connection after asset check
    _database = await _initDB();
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'duas.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // ── Categories core table ──────────────────────────
        await db.execute('''
          CREATE TABLE categories(
            category_id INTEGER PRIMARY KEY,
            category_icon TEXT
          )
        ''');

        // ── Category translations — one row per language ───
        // Supports: en, bn, ar, ur (add more anytime — no schema change)
        await db.execute('''
          CREATE TABLE category_translations(
            category_id   INTEGER NOT NULL,
            language_code TEXT    NOT NULL,
            title         TEXT    NOT NULL,
            PRIMARY KEY(category_id, language_code),
            FOREIGN KEY(category_id) REFERENCES categories(category_id)
          )
        ''');

        // ── Duas core table — no translation columns here ──
        await db.execute('''
          CREATE TABLE duas(
            id              INTEGER PRIMARY KEY,
            category_id     INTEGER NOT NULL,
            arabic          TEXT,
            audio_url       TEXT,
            is_favorite     INTEGER DEFAULT 0,
            is_bookmarked   INTEGER DEFAULT 0,
            FOREIGN KEY(category_id) REFERENCES categories(category_id)
          )
        ''');

        // ── Dua translations — all translatable fields here ─
        // title, transliteration, translation, reference, description
        // description and audio_url are optional — can be null
        await db.execute('''
          CREATE TABLE dua_translations(
            dua_id            INTEGER NOT NULL,
            language_code     TEXT    NOT NULL,
            title             TEXT,
            transliteration   TEXT,
            translation_text  TEXT,
            reference         TEXT,
            description       TEXT,
            PRIMARY KEY(dua_id, language_code),
            FOREIGN KEY(dua_id) REFERENCES duas(id)
          )
        ''');

        // ── Index for fast JOIN queries ────────────────────
        await db.execute('''
          CREATE INDEX idx_dua_translations
          ON dua_translations(dua_id, language_code)
        ''');

        await db.execute('''
          CREATE INDEX idx_cat_translations
          ON category_translations(category_id, language_code)
        ''');

        // ── User interactions ──────────────────────────────
        await db.execute('''
          CREATE TABLE user_interactions(
            user_id       TEXT    NOT NULL,
            dua_id        INTEGER NOT NULL,
            is_favorite   INTEGER DEFAULT 0,
            is_bookmarked INTEGER DEFAULT 0,
            PRIMARY KEY(user_id, dua_id),
            FOREIGN KEY(dua_id) REFERENCES duas(id)
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
    await db.insert('categories', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertCategoryTranslation({
    required int categoryId,
    required String languageCode,
    required String title,
  }) async {
    final db = await database;
    await db.insert(
      'category_translations',
      {
        'category_id':   categoryId,
        'language_code': languageCode,
        'title':         title,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all categories with resolved language + COALESCE fallback to English
  Future<List<Map<String, dynamic>>> getAllCategories(String languageCode) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        c.category_id,
        c.category_icon,
        COALESCE(t.title, fallback.title, '') AS category_title
      FROM categories c
      LEFT JOIN category_translations t
        ON c.category_id = t.category_id AND t.language_code = ?
      LEFT JOIN category_translations fallback
        ON c.category_id = fallback.category_id AND fallback.language_code = 'en'
      ORDER BY c.category_id ASC
    ''', [languageCode]);
  }

  // ── Duas ────────────────────────────────────────────────

  Future<void> insertDua(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('duas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertDuaTranslation({
    required int duaId,
    required String languageCode,
    required String title,
    required String transliteration,
    required String translationText,
    required String reference,
    String? description,
  }) async {
    final db = await database;
    await db.insert(
      'dua_translations',
      {
        'dua_id':           duaId,
        'language_code':    languageCode,
        'title':            title,
        'transliteration':  transliteration,
        'translation_text': translationText,
        'reference':        reference,
        'description':      description, // nullable — fine if null
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get duas by category — JOIN resolves language, COALESCE falls back to English
  Future<List<Map<String, dynamic>>> getDuasByCategory({
    required int categoryId,
    required String languageCode,
    required String userId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        d.id,
        d.category_id,
        d.arabic,
        d.audio_url,
        COALESCE(t.title,            fb.title,            '') AS title,
        COALESCE(t.transliteration,  fb.transliteration,  '') AS transliteration,
        COALESCE(t.translation_text, fb.translation_text, '') AS translation_text,
        COALESCE(t.reference,        fb.reference,        '') AS reference,
        COALESCE(t.description,      fb.description,      NULL) AS description,
        COALESCE(ui.is_favorite,  d.is_favorite,  0) AS is_favorite,
        COALESCE(ui.is_bookmarked,d.is_bookmarked,0) AS is_bookmarked,
        cat_t.category_title
      FROM duas d
      LEFT JOIN dua_translations t
        ON d.id = t.dua_id AND t.language_code = ?
      LEFT JOIN dua_translations fb
        ON d.id = fb.dua_id AND fb.language_code = 'en'
      LEFT JOIN user_interactions ui
        ON d.id = ui.dua_id AND ui.user_id = ?
      LEFT JOIN (
        SELECT
          c2.category_id,
          COALESCE(t2.title, fb2.title, '') AS category_title
        FROM categories c2
        LEFT JOIN category_translations t2
          ON c2.category_id = t2.category_id AND t2.language_code = ?
        LEFT JOIN category_translations fb2
          ON c2.category_id = fb2.category_id AND fb2.language_code = 'en'
      ) cat_t ON d.category_id = cat_t.category_id
      WHERE d.category_id = ?
      ORDER BY d.id ASC
    ''', [languageCode, userId, languageCode, categoryId]);
  }

  // Get ALL duas — same JOIN logic as getDuasByCategory but no WHERE filter
  Future<List<Map<String, dynamic>>> getAllDuas({
    required String languageCode,
    required String userId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT
      d.id,
      d.category_id,
      d.arabic,
      d.audio_url,
      COALESCE(t.title,            fb.title,            '') AS title,
      COALESCE(t.transliteration,  fb.transliteration,  '') AS transliteration,
      COALESCE(t.translation_text, fb.translation_text, '') AS translation_text,
      COALESCE(t.reference,        fb.reference,        '') AS reference,
      COALESCE(t.description,      fb.description,      NULL) AS description,
      COALESCE(ui.is_favorite,   d.is_favorite,   0) AS is_favorite,
      COALESCE(ui.is_bookmarked, d.is_bookmarked,  0) AS is_bookmarked,
      cat_t.category_title
    FROM duas d
    LEFT JOIN dua_translations t
      ON d.id = t.dua_id AND t.language_code = ?
    LEFT JOIN dua_translations fb
      ON d.id = fb.dua_id AND fb.language_code = 'en'
    LEFT JOIN user_interactions ui
      ON d.id = ui.dua_id AND ui.user_id = ?
    LEFT JOIN (
      SELECT
        c2.category_id,
        COALESCE(t2.title, fb2.title, '') AS category_title
      FROM categories c2
      LEFT JOIN category_translations t2
        ON c2.category_id = t2.category_id AND t2.language_code = ?
      LEFT JOIN category_translations fb2
        ON c2.category_id = fb2.category_id AND fb2.language_code = 'en'
    ) cat_t ON d.category_id = cat_t.category_id
    ORDER BY d.id ASC
  ''', [languageCode, userId, languageCode]);
  }


  // ── Favorites & Bookmarks ───────────────────────────────

  Future<void> upsertUserInteraction({
    required String userId,
    required int duaId,
    required bool isFavorite,
    required bool isBookmarked,
  }) async {
    final db = await database;
    await db.insert(
      'user_interactions',
      {
        'user_id':      userId,
        'dua_id':       duaId,
        'is_favorite':  isFavorite ? 1 : 0,
        'is_bookmarked':isBookmarked ? 1 : 0,
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
        d.id,
        d.category_id,
        d.arabic,
        d.audio_url,
        COALESCE(t.title,            fb.title,            '') AS title,
        COALESCE(t.transliteration,  fb.transliteration,  '') AS transliteration,
        COALESCE(t.translation_text, fb.translation_text, '') AS translation_text,
        COALESCE(t.reference,        fb.reference,        '') AS reference,
        COALESCE(t.description,      fb.description,      NULL) AS description,
        ui.is_favorite,
        ui.is_bookmarked
      FROM duas d
      INNER JOIN user_interactions ui
        ON d.id = ui.dua_id AND ui.user_id = ? AND ui.is_favorite = 1
      LEFT JOIN dua_translations t
        ON d.id = t.dua_id AND t.language_code = ?
      LEFT JOIN dua_translations fb
        ON d.id = fb.dua_id AND fb.language_code = 'en'
      ORDER BY d.id ASC
    ''', [userId, languageCode]);
  }

  Future<List<Map<String, dynamic>>> getBookmarkedForUser({
    required String userId,
    required String languageCode,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        d.id,
        d.category_id,
        d.arabic,
        d.audio_url,
        COALESCE(t.title,            fb.title,            '') AS title,
        COALESCE(t.transliteration,  fb.transliteration,  '') AS transliteration,
        COALESCE(t.translation_text, fb.translation_text, '') AS translation_text,
        COALESCE(t.reference,        fb.reference,        '') AS reference,
        COALESCE(t.description,      fb.description,      NULL) AS description,
        ui.is_favorite,
        ui.is_bookmarked
      FROM duas d
      INNER JOIN user_interactions ui
        ON d.id = ui.dua_id AND ui.user_id = ? AND ui.is_bookmarked = 1
      LEFT JOIN dua_translations t
        ON d.id = t.dua_id AND t.language_code = ?
      LEFT JOIN dua_translations fb
        ON d.id = fb.dua_id AND fb.language_code = 'en'
      ORDER BY d.id ASC
    ''', [userId, languageCode]);
  }

  Future<void> replaceUserInteractions(
      String userId, List<Map<String, dynamic>> interactions) async {
    if (interactions.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_interactions',
          where: 'user_id = ?', whereArgs: [userId]);
      for (final row in interactions) {
        await txn.insert('user_interactions', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getGuestInteractions() async {
    final db = await database;
    return await db.query('user_interactions',
        where: 'user_id = ?', whereArgs: ['guest']);
  }

  Future<void> migrateGuestToUser(String userId) async {
    final db = await database;
    await db.update('user_interactions', {'user_id': userId},
        where: 'user_id = ?', whereArgs: ['guest']);
  }

  Future<Map<String, dynamic>?> getUserInteractionForDua(
      String userId, int duaId) async {
    final db = await database;
    final result = await db.query('user_interactions',
        where: 'user_id = ? AND dua_id = ?',
        whereArgs: [userId, duaId],
        limit: 1);
    return result.isNotEmpty ? result.first : null;
  }
}