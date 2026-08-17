import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_model.dart';

class BookmarkStorage {
  static const _key = 'quran_bookmarks';
  static const _lastReadKey = 'quran_last_read_page';

  Future<List<BookmarkModel>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => BookmarkModel.fromMap(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> addBookmark(BookmarkModel bm) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadBookmarks();
    // Remove duplicate page if exists
    list.removeWhere((b) => b.pageNumber == bm.pageNumber);
    list.insert(0, bm);
    await prefs.setStringList(
        _key, list.map((b) => jsonEncode(b.toMap())).toList());
  }

  Future<void> removeBookmark(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadBookmarks();
    list.removeWhere((b) => b.pageNumber == pageNumber);
    await prefs.setStringList(
        _key, list.map((b) => jsonEncode(b.toMap())).toList());
  }

  Future<bool> isBookmarked(int pageNumber) async {
    final list = await loadBookmarks();
    return list.any((b) => b.pageNumber == pageNumber);
  }

  Future<void> saveLastRead(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadKey, pageNumber);
  }

  Future<int> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadKey) ?? 1;
  }
}