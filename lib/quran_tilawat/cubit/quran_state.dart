import '../models/surah_model.dart';
import '../models/bookmark_model.dart';

abstract class QuranState {}

class QuranInitial extends QuranState {}
class QuranLoading extends QuranState {}

class QuranLoaded extends QuranState {
  final List<SurahModel> surahs;
  final List<SurahModel> searchResults;
  final List<BookmarkModel> bookmarks;
  final int lastReadPage;
  final String searchQuery;

  QuranLoaded({
    required this.surahs,
    required this.searchResults,
    required this.bookmarks,
    required this.lastReadPage,
    this.searchQuery = '',
  });

  QuranLoaded copyWith({
    List<SurahModel>? surahs,
    List<SurahModel>? searchResults,
    List<BookmarkModel>? bookmarks,
    int? lastReadPage,
    String? searchQuery,
  }) =>
      QuranLoaded(
        surahs: surahs ?? this.surahs,
        searchResults: searchResults ?? this.searchResults,
        bookmarks: bookmarks ?? this.bookmarks,
        lastReadPage: lastReadPage ?? this.lastReadPage,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class QuranError extends QuranState {
  final String message;
  QuranError(this.message);
}