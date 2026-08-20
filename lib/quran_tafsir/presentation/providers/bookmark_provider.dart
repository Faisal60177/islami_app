import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/bookmarked_verse.dart';
import '../../data/datasources/bookmark_local_datasource.dart';
import '../../data/datasources/bookmark_remote_datasource.dart';
import '../../domain/repositories/bookmark_repository.dart';
import 'package:muslim_app/Menu/auth/auth_notifier.dart';
import 'package:muslim_app/Menu/auth/auth_state.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(
    local: BookmarkLocalDataSource(),
    remote: BookmarkRemoteDataSource(),
  );
});

final bookmarkNotifierProvider =
StateNotifierProvider<BookmarkNotifier, List<BookmarkedVerse>>((ref) {
  return BookmarkNotifier(ref);
});

class BookmarkNotifier extends StateNotifier<List<BookmarkedVerse>> {
  final Ref _ref;
  StreamSubscription<List<BookmarkedVerse>>? _remoteSub;
  String? _activeUid;

  BookmarkNotifier(this._ref) : super([]) {
    _init();
  }

  BookmarkRepository get _repo => _ref.read(bookmarkRepositoryProvider);

  void _init() {
    final auth = _ref.read(authNotifierProvider);
    _handleAuthChange(auth.isLoggedIn ? auth.uid : null);

    // লগইন/লগআউট হওয়ার মুহূর্তে (uid বদলালে) স্বয়ংক্রিয়ভাবে
    // local ↔ remote সোর্স সুইচ হবে।
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final prevUid = previous?.isLoggedIn == true ? previous!.uid : null;
      final nextUid = next.isLoggedIn ? next.uid : null;
      if (prevUid != nextUid) {
        _handleAuthChange(nextUid);
      }
    });
  }

  Future<void> _handleAuthChange(String? uid) async {
    await _remoteSub?.cancel();
    _remoteSub = null;
    _activeUid = uid;

    if (uid == null) {
      // সাইন-আউট (বা অ্যাপ শুরু হয়েছে, লগইন করা নেই) — local থেকে দেখাও।
      state = await _repo.getLocalBookmarks();
      return;
    }

    // এইমাত্র লগইন হয়েছে — আগে local-এর সব bookmark Firestore-এ push করো,
    // তারপর Firestore-কে single source of truth ধরে stream শুনতে থাকো।
    await _repo.migrateLocalToRemote(uid);
    _remoteSub = _repo.watchRemoteBookmarks(uid).listen((bookmarks) {
      state = bookmarks;
    });
  }

  bool isBookmarked(String verseKey) =>
      state.any((b) => b.verse.verseKey == verseKey);

  Future<void> toggle(Verse verse) async {
    final uid = _activeUid;
    final alreadyBookmarked = isBookmarked(verse.verseKey);

    if (uid == null) {
      // Local mode — SharedPreferences-এর কোনো stream নেই, তাই লিখে
      // দেওয়ার পর state ম্যানুয়ালি রিফ্রেশ করতে হয়।
      if (alreadyBookmarked) {
        await _repo.removeLocal(verse.verseKey);
      } else {
        await _repo.addLocal(verse);
      }
      state = await _repo.getLocalBookmarks();
      return;
    }

    // Remote mode — Firestore write হলেই stream subscription নিজে থেকে
    // state আপডেট করে দেবে।
    if (alreadyBookmarked) {
      await _repo.removeRemote(uid, verse.verseKey);
    } else {
      await _repo.addRemote(uid, verse);
    }
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    super.dispose();
  }
}