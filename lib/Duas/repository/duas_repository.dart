import 'package:flutter/foundation.dart';
import '../database/local/duas_sqflite.dart';
import '../model/duas_model.dart';
import '../model/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

class DuasRepository {
  final DuasSqflite dbHelper = DuasSqflite();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ── Categories ──────────────────────────────────────
  Future<List<CategoryModel>> getAllCategories() async {
    final data = await dbHelper.getAllCategories();
    return data.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> insertCategory(CategoryModel cat) async {
    await dbHelper.insertCategory(cat.toMap());
  }

  // ✅ Firestore field 'ID' → mapped to 'category_id' for CategoryModel
  Future<void> syncCategoriesFromFirestore() async {
    final snapshot = await _firestore.collection('categories duas').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = CategoryModel.fromMap({
        'category_id':    data['ID'],              // ✅ Firestore 'ID' → model 'category_id'
        'category_title': data['category_title'],
        'category_icon':  data['category_icon'] ?? '',
      });
      await insertCategory(category);
    }
  }

  /// ── Duas ────────────────────────────────────────────
  Future<List<DuasModel>> getAllDuas() async {
    final data = await dbHelper.getAllDuas();
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<List<DuasModel>> getDuasByCategory(String categoryTitle) async {
    final data = await dbHelper.getDuasByCategory(categoryTitle);
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<void> insertDua(DuasModel dua) async {
    await dbHelper.insertDua(dua.toMap());
  }

  Future<void> updateDua(DuasModel dua) async {
    await dbHelper.updateDua(dua.toMap(), dua.id);
  }

  Future<void> deleteDua(int id) async {
    await dbHelper.deleteDua(id);
  }

  Future<void> syncDuasFromFirestore() async {
    final existingCategories = await getAllCategories();
    final validCategoryIds = existingCategories.map((c) => c.categoryId).toSet();

    final idToTitle = {
      for (var c in existingCategories) c.categoryId: c.categoryTitle
    };

    final dbDuas = await getAllDuas();
    final existingMap = {for (var d in dbDuas) d.id: d};

    final snapshot = await _firestore.collection('duas').get();

    // ✅ Parse all docs first — outside the transaction (no async Firestore inside txn)
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toUpdate = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      int categoryId = 0;
      if (data['category_id'] != null) {
        categoryId = (data['category_id'] as num).toInt();
      } else if (data['category'] != null) {
        categoryId = int.tryParse(data['category'].toString()) ?? 0;
      }

      if (!validCategoryIds.contains(categoryId)) {
        debugPrint('⚠️ Skipping dua ${doc.id} — category_id $categoryId not found');
        continue;
      }

      final dua = DuasModel.fromMap({
        'id':              data['id'] ?? int.tryParse(doc.id) ?? 0,
        'category_id':     categoryId,
        'category_title':  idToTitle[categoryId] ?? '',
        'arabic':          data['arabic'] ?? '',
        'transliteration': data['transliteration'] ?? '',
        'translation_en':  data['translation_en'] ?? '',
        'translation_bn':  data['translation_bn'] ?? '',
        'reference':       data['reference'] ?? '',
        'tags':            data['tags'] ?? '',
        'audio_url':       data['audio_url'],
      });

      if (!existingMap.containsKey(dua.id)) {
        // ✅ new dua — insert as-is
        toInsert.add(dua.toMap());
      } else {
        // ✅ existing dua — preserve user's favorite/bookmark state
        final old = existingMap[dua.id]!;
        final updatedMap = dua.toMap();
        updatedMap['is_favorite']  = old.isFavorite  ? 1 : 0;
        updatedMap['is_bookmarked'] = old.isBookmarked ? 1 : 0;
        toUpdate.add(updatedMap);
      }
    }

    // ✅ Single transaction — all inserts + updates in one batch
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      for (final row in toInsert) {
        await txn.insert('duas', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in toUpdate) {
        await txn.update('duas', row,
            where: 'id = ?', whereArgs: [row['id']]);
      }
    });
  }

  /// ── Favorites / Bookmarks ───────────────────────────
  Future<void> toggleFavorite(DuasModel dua, String userId) async {
    await dbHelper.upsertUserInteraction(
      userId: userId,
      duaId: dua.id,
      isFavorite: dua.isFavorite,
      isBookmarked: dua.isBookmarked,
    );
    if (userId != 'guest') await _syncInteractionToFirestore(userId, dua);
  }

  Future<void> toggleBookmark(DuasModel dua, String userId) async {
    await dbHelper.upsertUserInteraction(
      userId: userId,
      duaId: dua.id,
      isFavorite: dua.isFavorite,
      isBookmarked: dua.isBookmarked,
    );
    if (userId != 'guest') await _syncInteractionToFirestore(userId, dua);
  }

  Future<void> _syncInteractionToFirestore(String userId, DuasModel dua) async {
    await _firestore
        .collection('user_interactions')
        .doc(userId)
        .collection('duas')
        .doc(dua.id.toString())
        .set({
      'dua_id':       dua.id,
      'is_favorite':  dua.isFavorite,
      'is_bookmarked':dua.isBookmarked,
      'updated_at':   FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> onUserLogin(String userId) async {
    // ✅ Step 1 — read guest rows BEFORE migrating
    final guestRows = await dbHelper.getGuestInteractions();

    // ✅ Step 2 — migrate SQLite guest → real userId first
    await dbHelper.migrateGuestToUser(userId);

    // ✅ Step 3 — push guest rows to Firestore under real userId
    for (final row in guestRows) {
      await _firestore
          .collection('user_interactions')
          .doc(userId)
          .collection('duas')
          .doc(row['dua_id'].toString())
          .set({
        'dua_id':       row['dua_id'],
        'is_favorite':  row['is_favorite'] == 1,
        'is_bookmarked':row['is_bookmarked'] == 1,
        'updated_at':   FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // ✅ Step 4 — pull Firestore back (now safe — Firestore already has local data)
    await syncUserInteractionsFromFirestore(userId);
  }


  Future<List<DuasModel>> getFavoritesForUser(String userId) async {
    final data = await dbHelper.getFavoritesForUser(userId);
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<List<DuasModel>> getBookmarkedForUser(String userId) async {
    final data = await dbHelper.getBookmarkedForUser(userId);
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<void> syncUserInteractionsFromFirestore(String userId) async {
    final snapshot = await _firestore
        .collection('user_interactions')
        .doc(userId)
        .collection('duas')
        .get();
    final interactions = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'user_id':      userId,
        'dua_id':       (data['dua_id'] as num).toInt(),
        'is_favorite':  (data['is_favorite'] == true) ? 1 : 0,
        'is_bookmarked':(data['is_bookmarked'] == true) ? 1 : 0,
      };
    }).toList();
    await dbHelper.replaceUserInteractions(userId, interactions);
  }

  Future<Map<String, dynamic>?> getUserInteractionForDua(
      String userId, int duaId) async {
    return await dbHelper.getUserInteractionForDua(userId, duaId);
  }
}