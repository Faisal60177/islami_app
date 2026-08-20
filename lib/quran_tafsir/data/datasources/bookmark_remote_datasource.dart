import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verse_model.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/bookmarked_verse.dart';

/// Stores bookmarks in Firestore for signed-in users, under
/// users/{uid}/bookmarks/{verseKey} — one doc per bookmarked ayah, so
/// toggling a single verse never touches the rest of the list.
class BookmarkRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('bookmarks');

  /// Real-time bookmark list for this user — the UI stays in sync across
  /// devices without any manual refresh.
  Stream<List<BookmarkedVerse>> watch(String uid) {
    return _col(uid)
        .orderBy('bookmarked_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      final verse =
      VerseModel.fromJson(data['verse'] as Map<String, dynamic>);
      final ts = data['bookmarked_at'];
      final ms = ts is Timestamp
          ? ts.millisecondsSinceEpoch
          : (ts as int? ?? 0);
      return BookmarkedVerse(verse: verse, bookmarkedAtMs: ms);
    }).toList());
  }

  Future<void> add(String uid, Verse verse) async {
    await _col(uid).doc(verse.verseKey).set({
      'verse': VerseModel.fromEntity(verse).toJson(),
      'bookmarked_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String uid, String verseKey) async {
    await _col(uid).doc(verseKey).delete();
  }

  /// One-time push of locally-saved bookmarks into Firestore, called
  /// right after login. Uses merge so it's safe to run even if some of
  /// these verses are already bookmarked remotely.
  Future<void> migrateFromLocal(
      String uid, List<BookmarkedVerse> localBookmarks) async {
    if (localBookmarks.isEmpty) return;
    final batch = _firestore.batch();
    for (final b in localBookmarks) {
      final docRef = _col(uid).doc(b.verse.verseKey);
      batch.set(
        docRef,
        {
          'verse': VerseModel.fromEntity(b.verse).toJson(),
          'bookmarked_at':
          Timestamp.fromMillisecondsSinceEpoch(b.bookmarkedAtMs),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}