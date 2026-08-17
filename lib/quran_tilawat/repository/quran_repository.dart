import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah_model.dart';
import 'bookmark_storage.dart';
import '../models/bookmark_model.dart';

const int kTotalPdfPages = 619;

// The PDF page range that contains actual quran_tilawat text
// Page 3 = first quran_tilawat page (Surah Al-Fatiha)
// Page 612 = last quran_tilawat page (end of Surah An-Nas)
const int kQuranFirstPage = 1;    // PDF page 3 = quran_tilawat page 1
const int kQuranLastPage  = 619;  // PDF page 612 = quran_tilawat page 604

// Convert between "Surah page number" (1-604 in your metadata JSON)
// and "PDF image file number" (3-612 in your assets folder)
int surahPageToPdfPage(int surahPage) => surahPage;
int pdfPageToSurahPage(int pdfPage)   => pdfPage;

class QuranRepository {
  final BookmarkStorage _storage = BookmarkStorage();
  List<SurahModel>? _cachedSurahs;

  Future<List<SurahModel>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    final raw  = await rootBundle.loadString('assets/json/quran_metadata.json');
    final map  = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['surahs'] as List;
    _cachedSurahs = list.map((e) => SurahModel.fromJson(e)).toList();
    return _cachedSurahs!;
  }

  Future<List<SurahModel>> searchSurahs(String query) async {
    final all = await loadSurahs();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
    s.nameEn.toLowerCase().contains(q) ||
        s.nameTranslit.toLowerCase().contains(q) ||
        s.nameAr.contains(q) ||
        s.number.toString() == q)
        .toList();
  }

  Future<int> getParaPage(int paraNumber) async {
    final raw   = await rootBundle.loadString('assets/json/quran_metadata.json');
    final map   = jsonDecode(raw) as Map<String, dynamic>;
    final paras = map['paras'] as List;
    final match = paras.firstWhere(
          (e) => e['para'] == paraNumber,
      orElse: () => paras.first,
    );
    return match['page'] as int;
  }

  // Bookmark delegation
  Future<List<BookmarkModel>> loadBookmarks() => _storage.loadBookmarks();
  Future<void> addBookmark(BookmarkModel bm) => _storage.addBookmark(bm);
  Future<void> removeBookmark(int page) => _storage.removeBookmark(page);
  Future<bool> isBookmarked(int page) => _storage.isBookmarked(page);
  Future<void> saveLastRead(int page) => _storage.saveLastRead(page);
  Future<int> getLastRead() => _storage.getLastRead();
}