import '../../data/datasources/bookmark_local_datasource.dart';
import '../../data/datasources/bookmark_remote_datasource.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/bookmarked_verse.dart';

class BookmarkRepository {
  final BookmarkLocalDataSource _local;
  final BookmarkRemoteDataSource _remote;

  BookmarkRepository({
    required BookmarkLocalDataSource local,
    required BookmarkRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  Future<List<BookmarkedVerse>> getLocalBookmarks() => _local.getAll();

  Stream<List<BookmarkedVerse>> watchRemoteBookmarks(String uid) =>
      _remote.watch(uid);

  Future<void> addLocal(Verse verse) => _local.add(verse);
  Future<void> removeLocal(String verseKey) => _local.remove(verseKey);

  Future<void> addRemote(String uid, Verse verse) => _remote.add(uid, verse);
  Future<void> removeRemote(String uid, String verseKey) =>
      _remote.remove(uid, verseKey);

  /// Pushes any locally-saved bookmarks into Firestore, then clears
  /// local storage. Safe to call on every login — if there's nothing
  /// local, it's a no-op.
  Future<void> migrateLocalToRemote(String uid) async {
    final localBookmarks = await _local.getAll();
    if (localBookmarks.isEmpty) return;
    await _remote.migrateFromLocal(uid, localBookmarks);
    await _local.clear();
  }
}