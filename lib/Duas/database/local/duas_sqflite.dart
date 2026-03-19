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
      version: 2,
      onCreate: (db, version) async {
        // 🔹 Categories Table
        await db.execute('''
          CREATE TABLE categories(
            category TEXT PRIMARY KEY,
            category_title TEXT,
            category_icon TEXT
          )
        ''');

        // 🔹 Duas Table
        await db.execute('''
          CREATE TABLE duas(
            id INTEGER PRIMARY KEY,
            category TEXT,
            arabic TEXT,
            transliteration TEXT,
            translation_en TEXT,
            translation_bn TEXT,
            reference TEXT,
            tags TEXT,
            audio_url TEXT,
            is_favorite INTEGER DEFAULT 0,
            is_bookmarked INTEGER DEFAULT 0,
            FOREIGN KEY(category) REFERENCES categories(category)
          )
        ''');
      },
    );
  }

  /// Categories CRUD
  Future<void> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('categories', data,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  /// Duas CRUD
  Future<void> insertDua(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('duas', data, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getAllDuas() async {
    final db = await database;
    return await db.query('duas', orderBy: 'id ASC');
  }

  Future<void> updateDua(Map<String, dynamic> data, int id) async {
    final db = await database;
    await db.update('duas', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDua(int id) async {
    final db = await database;
    await db.delete('duas', where: 'id = ?', whereArgs: [id]);
  }
}