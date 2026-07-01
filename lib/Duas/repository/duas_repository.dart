import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local/duas_sqflite.dart';
import '../model/category_model.dart';
import '../model/duas_model.dart';

class DuasRepository {
  final DuasSqflite dbHelper = DuasSqflite();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initDatabase() async {
    await dbHelper.initFromAssetIfNeeded();
    _syncInBackground();
  }
  void _syncInBackground() {
    Future.microtask(() async {
      try {
        await syncCategoriesFromFirestore();
        await syncDuasFromFirestore();
        debugPrint('✅ Duas background sync complete');
      } catch (e) {
        debugPrint('⚠️ Duas sync skipped: $e');
      }
    });
  }


  // ── Categories ────────────────────────────────────────────

  Future<List<CategoryModel>> getAllCategories(String languageCode) async {
    final data = await dbHelper.getAllCategories(languageCode);
    return data.map((e) => CategoryModel.fromMap(e)).toList();
  }



  Future<void> syncCategoriesFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('categories_duas')
          .get();
      final db = await dbHelper.database;
      final List<int> firestoreIds = [];

      await db.transaction((txn) async {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final int categoryId =
          ((data['id'] ?? data['ID'] ?? 0) as num).toInt();
          firestoreIds.add(categoryId);

          await txn.insert(
            'categories',
            {
              'category_id':   categoryId,
              'category_icon': data['category_icon'] ?? '',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          final transSnap = await _firestore
              .collection('categories_duas')
              .doc(doc.id)
              .collection('translations')
              .get();

          for (var tDoc in transSnap.docs) {
            await txn.insert(
              'category_translations',
              {
                'category_id':   categoryId,
                'language_code': tDoc.id,
                'title':         tDoc.data()['title'] ?? '',
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      await dbHelper.deleteRemovedCategories(firestoreIds);
    } catch (e) {
      debugPrint('⚠️ syncCategoriesFromFirestore skipped: $e');
      rethrow; // ✅ caller handle
    }
  }

  // ── Duas ─────────────────────────────────────────────────

  Future<List<DuasModel>> getDuasByCategory({
    required int categoryId,
    required String languageCode,
    required String userId,
  }) async {
    final data = await dbHelper.getDuasByCategory(
      categoryId:   categoryId,
      languageCode: languageCode,
      userId:       userId,
    );
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<List<DuasModel>> getAllDuas({
    required String languageCode,
    required String userId,
  }) async {
    final data = await dbHelper.getAllDuas(
      languageCode: languageCode,
      userId:       userId,
    );
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<void> syncDuasFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('duas').get();
      final db = await dbHelper.database;
      final List<int> firestoreIds = [];

      await db.transaction((txn) async {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final int duaId = data['id'] ?? int.tryParse(doc.id) ?? 0;
          firestoreIds.add(duaId);

          await txn.insert(
            'duas',
            {
              'id':          duaId,
              'category_id': (data['category_id'] as num).toInt(),
              'arabic':      data['arabic'] ?? '',
              'audio_url':   data['audio_url'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          final transSnap = await _firestore
              .collection('duas')
              .doc(doc.id)
              .collection('translations')
              .get();

          for (var tDoc in transSnap.docs) {
            final t = tDoc.data();
            await txn.insert(
              'dua_translations',
              {
                'dua_id':           duaId,
                'language_code':    tDoc.id,
                'title':            t['title']            ?? '',
                'transliteration':  t['transliteration']  ?? '',
                'translation_text': t['translation_text'] ?? '',
                'reference':        t['reference']        ?? '',
                'description':      t['description'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      await dbHelper.deleteRemovedDuas(firestoreIds);
      debugPrint('✅ Duas synced from Firestore');
    } catch (e) {
      debugPrint('⚠️ syncDuasFromFirestore skipped: $e');
      rethrow;
    }
  }

  // ── Favorites & Bookmarks ─────────────────────────────────

  Future<Map<String, dynamic>?> getUserInteractionForDua(
      String userId, int duaId) async {
    return await dbHelper.getUserInteractionForDua(userId, duaId);
  }

  Future<void> toggleFavorite(DuasModel dua, String userId) async {
    await dbHelper.upsertUserInteraction(
      userId:       userId,
      duaId:        dua.id,
      isFavorite:   dua.isFavorite,
      isBookmarked: dua.isBookmarked,
    );
    if (userId != 'guest') await _syncInteractionToFirestore(userId, dua);
  }

  Future<void> toggleBookmark(DuasModel dua, String userId) async {
    await dbHelper.upsertUserInteraction(
      userId:       userId,
      duaId:        dua.id,
      isFavorite:   dua.isFavorite,
      isBookmarked: dua.isBookmarked,
    );
    if (userId != 'guest') await _syncInteractionToFirestore(userId, dua);
  }

  Future<void> _syncInteractionToFirestore(
      String userId, DuasModel dua) async {
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

  Future<List<DuasModel>> getFavoritesForUser({
    required String userId,
    required String languageCode,
  }) async {
    final data = await dbHelper.getFavoritesForUser(
      userId:       userId,
      languageCode: languageCode,
    );
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<List<DuasModel>> getBookmarkedForUser({
    required String userId,
    required String languageCode,
  }) async {
    final data = await dbHelper.getBookmarkedForUser(
      userId:       userId,
      languageCode: languageCode,
    );
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  // ── Auth events ───────────────────────────────────────────

  Future<void> onUserLogin(String userId) async {
    final guestRows = await dbHelper.getGuestInteractions();
    await dbHelper.migrateGuestToUser(userId);

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

    await syncUserInteractionsFromFirestore(userId);
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
        'is_favorite':  data['is_favorite']  == true ? 1 : 0,
        'is_bookmarked':data['is_bookmarked'] == true ? 1 : 0,
      };
    }).toList();

    await dbHelper.replaceUserInteractions(userId, interactions);
  }
}