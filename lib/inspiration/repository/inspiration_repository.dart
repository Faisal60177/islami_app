import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/inspiration_sqflite.dart';
import '../model/inspiration_category_model.dart';
import '../model/inspiration_model.dart';

class InspirationRepository {
  final InspirationSqflite dbHelper = InspirationSqflite();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Categories ────────────────────────────────────────────

  Future<List<InspirationCategoryModel>> getAllCategories(
      String languageCode) async {
    final data = await dbHelper.getAllCategories(languageCode);
    return data.map((e) => InspirationCategoryModel.fromMap(e)).toList();
  }

  Future<void> syncCategoriesFromFirestore() async {
    final snapshot =
    await _firestore.collection('inspiration_categories').get();
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final int categoryId =
        ((data['id'] ?? data['ID'] ?? 0) as num).toInt();

        // Insert core category — no color column
        await txn.insert(
          'inspiration_categories',
          {
            'category_id':   categoryId,
            'category_icon': data['category_icon'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Fetch translations subcollection
        final transSnap = await _firestore
            .collection('inspiration_categories')
            .doc(doc.id)
            .collection('translations')
            .get();

        for (var tDoc in transSnap.docs) {
          await txn.insert(
            'inspiration_category_translations',
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

    debugPrint('✅ Inspiration categories synced');
  }

  // ── Inspirations ─────────────────────────────────────────

  Future<List<InspirationModel>> getInspirationsByCategory({
    required int categoryId,
    required String languageCode,
    required String userId,
  }) async {
    final data = await dbHelper.getInspirationsByCategory(
      categoryId:   categoryId,
      languageCode: languageCode,
      userId:       userId,
    );
    return data.map((e) => InspirationModel.fromMap(e)).toList();
  }

  Future<List<InspirationModel>> getAllInspirations({
    required String languageCode,
    required String userId,
  }) async {
    final data = await dbHelper.getAllInspirations(
      languageCode: languageCode,
      userId:       userId,
    );
    return data.map((e) => InspirationModel.fromMap(e)).toList();
  }

  Future<void> syncInspirationsFromFirestore() async {
    final snapshot =
    await _firestore.collection('inspirations').get();
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final int inspirationId =
            data['id'] ?? int.tryParse(doc.id) ?? 0;

        // Step 1 — Insert core inspiration row
        // quote_arabic nullable — null for scholar/person quotes
        await txn.insert(
          'inspirations',
          {
            'id':           inspirationId,
            'category_id':  (data['category_id'] as num).toInt(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Step 2 — Fetch translations subcollection
        final transSnap = await _firestore
            .collection('inspirations')
            .doc(doc.id)
            .collection('translations')
            .get();

        // Step 3 — Insert each language translation row
        for (var tDoc in transSnap.docs) {
          final t = tDoc.data();
          await txn.insert(
            'inspiration_translations',
            {
              'inspiration_id': inspirationId,
              'language_code':  tDoc.id,
              'title':          t['title']      ?? '',
              'quote_text':     t['quote_text'] ?? '',
              'reference':      t['reference'],  // nullable
              'author':         t['author'],     // nullable
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    debugPrint('✅ Inspirations synced from Firestore');
  }

  // ── Favorites & Bookmarks ─────────────────────────────────

  Future<Map<String, dynamic>?> getUserInteractionForInspiration(
      String userId,
      int inspirationId,
      ) async {
    return await dbHelper.getUserInteractionForInspiration(
        userId, inspirationId);
  }

  Future<void> toggleFavorite(
      InspirationModel inspiration, String userId) async {
    await dbHelper.upsertUserInteraction(
      userId:        userId,
      inspirationId: inspiration.id,
      isFavorite:    inspiration.isFavorite,
      isBookmarked:  inspiration.isBookmarked,
    );
    if (userId != 'guest') {
      await _syncInteractionToFirestore(userId, inspiration);
    }
  }

  Future<void> toggleBookmark(
      InspirationModel inspiration, String userId) async {
    await dbHelper.upsertUserInteraction(
      userId:        userId,
      inspirationId: inspiration.id,
      isFavorite:    inspiration.isFavorite,
      isBookmarked:  inspiration.isBookmarked,
    );
    if (userId != 'guest') {
      await _syncInteractionToFirestore(userId, inspiration);
    }
  }

  Future<void> _syncInteractionToFirestore(
      String userId,
      InspirationModel inspiration,
      ) async {
    await _firestore
        .collection('user_inspiration_interactions')
        .doc(userId)
        .collection('inspirations')
        .doc(inspiration.id.toString())
        .set({
      'inspiration_id': inspiration.id,
      'is_favorite':    inspiration.isFavorite,
      'is_bookmarked':  inspiration.isBookmarked,
      'updated_at':     FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<InspirationModel>> getFavoritesForUser({
    required String userId,
    required String languageCode,
  }) async {
    final data = await dbHelper.getFavoritesForUser(
      userId:       userId,
      languageCode: languageCode,
    );
    return data.map((e) => InspirationModel.fromMap(e)).toList();
  }

  Future<List<InspirationModel>> getBookmarkedForUser({
    required String userId,
    required String languageCode,
  }) async {
    final data = await dbHelper.getBookmarkedForUser(
      userId:       userId,
      languageCode: languageCode,
    );
    return data.map((e) => InspirationModel.fromMap(e)).toList();
  }

  // ── Auth events ───────────────────────────────────────────

  Future<void> onUserLogin(String userId) async {
    final guestRows = await dbHelper.getGuestInteractions();
    await dbHelper.migrateGuestToUser(userId);

    for (final row in guestRows) {
      await _firestore
          .collection('user_inspiration_interactions')
          .doc(userId)
          .collection('inspirations')
          .doc(row['inspiration_id'].toString())
          .set({
        'inspiration_id': row['inspiration_id'],
        'is_favorite':    row['is_favorite'] == 1,
        'is_bookmarked':  row['is_bookmarked'] == 1,
        'updated_at':     FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await syncUserInteractionsFromFirestore(userId);
  }

  Future<void> syncUserInteractionsFromFirestore(String userId) async {
    final snapshot = await _firestore
        .collection('user_inspiration_interactions')
        .doc(userId)
        .collection('inspirations')
        .get();

    final interactions = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'user_id':        userId,
        'inspiration_id': (data['inspiration_id'] as num).toInt(),
        'is_favorite':    data['is_favorite']  == true ? 1 : 0,
        'is_bookmarked':  data['is_bookmarked'] == true ? 1 : 0,
      };
    }).toList();

    await dbHelper.replaceUserInteractions(userId, interactions);
  }
}