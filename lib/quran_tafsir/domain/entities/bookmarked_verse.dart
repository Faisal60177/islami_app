import 'verse.dart';
class BookmarkedVerse {
  final Verse verse;
  final int bookmarkedAtMs;

  const BookmarkedVerse({
    required this.verse,
    required this.bookmarkedAtMs,
  });
}