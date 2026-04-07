import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/quran_repository.dart';
import '../models/bookmark_model.dart';
import '../models/surah_model.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  final QuranRepository _repo;

  QuranCubit(this._repo) : super(QuranInitial());

  Future<void> init() async {
    emit(QuranLoading());
    try {
      final surahs     = await _repo.loadSurahs();
      final bookmarks  = await _repo.loadBookmarks();
      final lastRead   = await _repo.getLastRead();
      emit(QuranLoaded(
        surahs: surahs,
        searchResults: surahs,
        bookmarks: bookmarks,
        lastReadPage: lastRead,
      ));
    } catch (e) {
      emit(QuranError(e.toString()));
    }
  }

  Future<void> search(String query) async {
    final s = state;
    if (s is! QuranLoaded) return;
    final results = await _repo.searchSurahs(query);
    emit(s.copyWith(searchResults: results, searchQuery: query));
  }

  Future<void> toggleBookmark(int pageNumber, SurahModel surah) async {
    final s = state;
    if (s is! QuranLoaded) return;
    final already = await _repo.isBookmarked(pageNumber);
    if (already) {
      await _repo.removeBookmark(pageNumber);
    } else {
      await _repo.addBookmark(BookmarkModel(
        pageNumber: pageNumber,
        surahNumber: surah.number,
        surahNameAr: surah.nameAr,
        surahNameEn: surah.nameEn,
        savedAt: DateTime.now(),
      ));
    }
    final bookmarks = await _repo.loadBookmarks();
    emit(s.copyWith(bookmarks: bookmarks));
  }

  Future<void> saveLastRead(int page) async {
    await _repo.saveLastRead(page);
    final s = state;
    if (s is QuranLoaded) emit(s.copyWith(lastReadPage: page));
  }

  Future<int> getParaPage(int para) => _repo.getParaPage(para);
}