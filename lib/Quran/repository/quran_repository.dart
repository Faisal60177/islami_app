import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah_model.dart';
import 'bookmark_storage.dart';
import '../models/bookmark_model.dart';

// ── Your PDF page layout ────────────────────────────────────
// Total image files extracted from your PDF
const int kTotalPdfPages = 619;

// The PDF page range that contains actual Quran text
// Page 3 = first Quran page (Surah Al-Fatiha)
// Page 612 = last Quran page (end of Surah An-Nas)
const int kQuranFirstPage = 3;    // PDF page 3 = Quran page 1
const int kQuranLastPage  = 612;  // PDF page 612 = Quran page 604

// Convert between "Surah page number" (1-604 in your metadata JSON)
// and "PDF image file number" (3-612 in your assets folder)
int surahPageToPdfPage(int surahPage) => surahPage + 2;   // add 2
int pdfPageToSurahPage(int pdfPage)   => pdfPage - 2;     // subtract 2

class QuranRepository {
  final BookmarkStorage _storage = BookmarkStorage();
  List<SurahModel>? _cachedSurahs;

  Future<List<SurahModel>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    final raw  = await rootBundle.loadString('assets/json/quran_metadata.json');
    final list = jsonDecode(raw) as List;
    // Convert JSON page numbers (1-604) to PDF page numbers (3-612)
    _cachedSurahs = list.map((e) {
      final m = SurahModel.fromJson(e);
      return SurahModel(
        number:         m.number,
        nameAr:         m.nameAr,
        nameEn:         m.nameEn,
        nameTranslit:   m.nameTranslit,
        totalAyahs:     m.totalAyahs,
        revelationType: m.revelationType,
        page:           surahPageToPdfPage(m.page),  // now 3–612
        para:           m.para,
      );
    }).toList();
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

  /// Returns page number for a given para (1-based)
  Future<int> getParaPage(int paraNumber) async {
    final all = await loadSurahs();
    final match = all.firstWhere(
          (s) => s.para == paraNumber,
      orElse: () => all.first,
    );
    // Convert Surah page (1-604) to PDF page (3-612)
    return surahPageToPdfPage(match.page);
  }

  // Bookmark delegation
  Future<List<BookmarkModel>> loadBookmarks() => _storage.loadBookmarks();
  Future<void> addBookmark(BookmarkModel bm) => _storage.addBookmark(bm);
  Future<void> removeBookmark(int page) => _storage.removeBookmark(page);
  Future<bool> isBookmarked(int page) => _storage.isBookmarked(page);
  Future<void> saveLastRead(int page) => _storage.saveLastRead(page);
  Future<int> getLastRead() => _storage.getLastRead();
}