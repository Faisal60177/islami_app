import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/masail_sqflite.dart';
import '../model/masail_model.dart';
import '../model/masail_category_model.dart';

class MasailRepository {
  final MasailSqflite dbHelper = MasailSqflite();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initDatabase() async {
    await dbHelper.initFromAssetIfNeeded();
    _syncInBackground();
  }


  void _syncInBackground() {
    Future.microtask(() async {
      try {
        await syncCategoriesFromFirestore();
        await syncMasailFromFirestore();
        debugPrint('✅ Masail background sync complete');
      } catch (e) {
        debugPrint('⚠️ Masail sync skipped: $e');
      }
    });
  }


  // ── Categories ────────────────────────────────────────────

  Future<List<MasailCategoryModel>> getAllCategories(String languageCode) async {
    final data = await dbHelper.getAllCategories(languageCode);
    return data.map((e) => MasailCategoryModel.fromMap(e)).toList();
  }

Future<void> syncCategoriesFromFirestore() async {
try {
    final snapshot = await _firestore.collection('categories_masail').get();
    final db = await dbHelper.database;
    final List<int> firestoreIds = [];

    await db.transaction((txn) async {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final int categoryId = ((data['id'] ?? data['ID'] ?? 0) as num).toInt();
        firestoreIds.add(categoryId);

        // Insert core category row
        await txn.insert(
          'masail_categories',
          {
            'category_id':   categoryId,
            'category_icon': data['category_icon'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Fetch translations subcollection: en, bn, ar, ur
        final transSnap = await _firestore
            .collection('categories_masail')
            .doc(doc.id)
            .collection('translations')
            .get();

        for (var tDoc in transSnap.docs) {
          await txn.insert(
            'masail_category_translations',
            {
              'category_id':   categoryId,
              'language_code': tDoc.id,          // 'en', 'bn', 'ar', 'ur'
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
  rethrow;
}
}


  // ── Masail ────────────────────────────────────────────────

  Future<List<MasailModel>> getMasailByCategory({
    required int categoryId,
    required String languageCode,
    required String userId,
  }) async {
    final data = await dbHelper.getMasailByCategory(
      categoryId:   categoryId,
      languageCode: languageCode,
      userId:       userId,
    );
    return data.map((e) => MasailModel.fromMap(e)).toList();
  }

  Future<List<MasailModel>> getAllMasail({
    required String languageCode,
    required String userId,
  }) async {
    final data = await dbHelper.getAllMasail(
      languageCode: languageCode,
      userId:       userId,
    );
    return data.map((e) => MasailModel.fromMap(e)).toList();
  }

Future<void> syncMasailFromFirestore() async {
try {
    final snapshot = await _firestore.collection('masail').get();
    final db = await dbHelper.database;
    final List<int> firestoreIds = [];

    await db.transaction((txn) async {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final int masailId = data['id'] ?? int.tryParse(doc.id) ?? 0;
        firestoreIds.add(masailId);

        // Step 1 — Insert core masail row
        // arabic is language-independent — stored once in core table
        await txn.insert(
          'masail',
          {
            'id':          masailId,
            'category_id': (data['category_id'] as num).toInt(),
            'arabic':      data['arabic'],   // nullable — fine
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Step 2 — Fetch translations subcollection
        final transSnap = await _firestore
            .collection('masail')
            .doc(doc.id)
            .collection('translations')
            .get();

        // Step 3 — Insert each language translation row
        // Each doc id is the language code: 'en', 'bn', 'ar', 'ur'
        for (var tDoc in transSnap.docs) {
          final t = tDoc.data();
          await txn.insert(
            'masail_translations',
            {
              'masail_id':     masailId,
              'language_code': tDoc.id,            // 'en', 'bn', 'ar', 'ur'
              'question':      t['question']  ?? '',
              'answer':        t['answer']    ?? '',
              'reference':     t['reference'] ?? '',
              'madhab':        t['madhab'],          // nullable — fine if null
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
    await dbHelper.deleteRemovedMasail(firestoreIds);
} catch (e) {
  debugPrint('⚠️ syncMasailFromFirestore skipped: $e');
  rethrow;
}
}

  // ── Bookmarks ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserBookmarkForMasail(
      String userId, int masailId) async {
    return await dbHelper.getUserBookmarkForMasail(userId, masailId);
  }

  Future<void> toggleBookmark(MasailModel masail, String userId) async {
    await dbHelper.upsertUserBookmark(
      userId:       userId,
      masailId:     masail.id,
      isBookmarked: masail.isBookmarked,
    );
    // Sync to Firestore for logged-in users only
    if (userId != 'guest') await _syncBookmarkToFirestore(userId, masail);
  }

  Future<void> _syncBookmarkToFirestore(
      String userId, MasailModel masail) async {
    await _firestore
        .collection('masail_user_bookmarks')
        .doc(userId)
        .collection('masail')
        .doc(masail.id.toString())
        .set({
      'masail_id':     masail.id,
      'is_bookmarked': masail.isBookmarked,
      'updated_at':    FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<MasailModel>> getBookmarkedForUser({
    required String userId,
    required String languageCode,
  }) async {
    final data = await dbHelper.getBookmarkedForUser(
      userId:       userId,
      languageCode: languageCode,
    );
    return data.map((e) => MasailModel.fromMap(e)).toList();
  }

  // ── Auth events ───────────────────────────────────────────

  Future<void> onUserLogin(String userId) async {
    final guestRows = await dbHelper.getGuestBookmarks();
    await dbHelper.migrateGuestToUser(userId);

    // Push guest bookmarks up to Firestore under the real user
    for (final row in guestRows) {
      await _firestore
          .collection('masail_user_bookmarks')
          .doc(userId)
          .collection('masail')
          .doc(row['masail_id'].toString())
          .set({
        'masail_id':     row['masail_id'],
        'is_bookmarked': row['is_bookmarked'] == 1,
        'updated_at':    FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await syncUserBookmarksFromFirestore(userId);
  }

  Future<void> syncUserBookmarksFromFirestore(String userId) async {
    final snapshot = await _firestore
        .collection('masail_user_bookmarks')
        .doc(userId)
        .collection('masail')
        .get();

    final bookmarks = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'user_id':       userId,
        'masail_id':     (data['masail_id'] as num).toInt(),
        'is_bookmarked': data['is_bookmarked'] == true ? 1 : 0,
      };
    }).toList();

    await dbHelper.replaceUserBookmarks(userId, bookmarks);
  }
}