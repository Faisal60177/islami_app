import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse_model.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/bookmarked_verse.dart';

/// Stores bookmarks on-device for signed-out users. Backed by a single
/// SharedPreferences string key holding a JSON map keyed by verseKey, so
/// add/remove/lookup are all O(1) without re-parsing the whole file
/// more than once per call.
class BookmarkLocalDataSource {
  static const _prefsKey = 'quran_local_bookmarks';

  Future<Map<String, dynamic>> _readRaw(SharedPreferences prefs) async {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<BookmarkedVerse>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readRaw(prefs);
    final list = map.entries.map((e) {
      final entry = e.value as Map<String, dynamic>;
      final verse = VerseModel.fromJson(entry['verse'] as Map<String, dynamic>);
      final bookmarkedAt = entry['bookmarked_at'] as int? ?? 0;
      return BookmarkedVerse(verse: verse, bookmarkedAtMs: bookmarkedAt);
    }).toList();
    list.sort((a, b) => b.bookmarkedAtMs.compareTo(a.bookmarkedAtMs));
    return list;
  }

  Future<void> add(Verse verse) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readRaw(prefs);
    map[verse.verseKey] = {
      'verse': VerseModel.fromEntity(verse).toJson(),
      'bookmarked_at': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> remove(String verseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readRaw(prefs);
    map.remove(verseKey);
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  /// Called right after a successful login migration — wipes local
  /// storage so the same bookmarks don't get re-migrated on next login.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}