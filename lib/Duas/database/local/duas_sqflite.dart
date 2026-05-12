import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'duas.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {

        // categories — primary key is category_id
        await db.execute('''
          CREATE TABLE categories(
            category_id INTEGER PRIMARY KEY,
            category_title TEXT NOT NULL,
            category_icon TEXT
          )
        ''');

        // duas — category_title stored for direct query without JOIN
        await db.execute('''
          CREATE TABLE duas(
            id INTEGER PRIMARY KEY,
            category_id INTEGER NOT NULL,
            category_title TEXT,
            arabic TEXT,
            transliteration TEXT,
            translation_en TEXT,
            translation_bn TEXT,
            reference TEXT,
            tags TEXT,
            audio_url TEXT,
            is_favorite INTEGER DEFAULT 0,
            is_bookmarked INTEGER DEFAULT 0,
            FOREIGN KEY(category_id) REFERENCES categories(category_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE user_interactions(
            user_id TEXT NOT NULL,
            dua_id INTEGER NOT NULL,
            is_favorite INTEGER DEFAULT 0,
            is_bookmarked INTEGER DEFAULT 0,
            PRIMARY KEY(user_id, dua_id),
            FOREIGN KEY(dua_id) REFERENCES duas(id)
          )
        ''');
      },
    );
  }

  /// ── Categories ──────────────────────────────────────
  Future<void> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('categories', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  /// ── Duas ────────────────────────────────────────────
  Future<void> insertDua(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('duas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllDuas() async {
    final db = await database;
    return await db.query('duas', orderBy: 'id ASC');
  }

  // ✅ query by category_title column
  Future<List<Map<String, dynamic>>> getDuasByCategory(String categoryTitle) async {
    final db = await database;
    return await db.query('duas',
        where: 'category_title = ?',
        whereArgs: [categoryTitle],
        orderBy: 'id ASC');
  }

  Future<void> updateDua(Map<String, dynamic> data, int id) async {
    final db = await database;
    await db.update('duas', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDua(int id) async {
    final db = await database;
    await db.delete('duas', where: 'id = ?', whereArgs: [id]);
  }

  /// ── User Interactions ───────────────────────────────
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
        'user_id': userId,
        'dua_id': duaId,
        'is_favorite': isFavorite ? 1 : 0,
        'is_bookmarked': isBookmarked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFavoritesForUser(String userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT d.*, ui.is_favorite, ui.is_bookmarked
      FROM duas d
      INNER JOIN user_interactions ui ON d.id = ui.dua_id
      WHERE ui.user_id = ? AND ui.is_favorite = 1
      ORDER BY d.id ASC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getBookmarkedForUser(String userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT d.*, ui.is_favorite, ui.is_bookmarked
      FROM duas d
      INNER JOIN user_interactions ui ON d.id = ui.dua_id
      WHERE ui.user_id = ? AND ui.is_bookmarked = 1
      ORDER BY d.id ASC
    ''', [userId]);
  }

  Future<void> replaceUserInteractions(
      String userId, List<Map<String, dynamic>> interactions) async {
    if (interactions.isEmpty) return; // ✅ don't wipe local if Firestore is empty
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