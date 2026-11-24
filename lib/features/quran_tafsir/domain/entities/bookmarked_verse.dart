import 'package:muslim_app/features/quran_tafsir/domain/entities/verse.dart';
class BookmarkedVerse {
  final Verse verse;
  final int bookmarkedAtMs;

  const BookmarkedVerse({
    required this.verse,
    required this.bookmarkedAtMs,
  });
}