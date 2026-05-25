import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';
import 'duas_state.dart';

class DuasCubit extends Cubit<DuasState> {
  final DuasRepository repository;
  String userId;
  String currentLanguageCode;

  DuasCubit(this.repository)
      : userId = 'guest',
        currentLanguageCode = 'en',
        super(DuaInitial());

  // ── Language update from Settings ──────────────────────
  // Call this whenever user changes language in settings
  void updateLanguage(String languageCode) {
    currentLanguageCode = languageCode;
  }

  // ── Categories ──────────────────────────────────────────

  void loadCategories() async {
    emit(DuaLoading());
    try {
      final categories =
      await repository.getAllCategories(currentLanguageCode);
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  // ── Duas ────────────────────────────────────────────────

  void loadDuasByCategory(int categoryId) async {
    emit(DuaLoading());
    try {
      final duas = await repository.getDuasByCategory(
        categoryId:   categoryId,
        languageCode: currentLanguageCode,
        userId:       userId,
      );
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void loadFavorites() async {
    emit(DuaLoading());
    try {
      final duas = await repository.getFavoritesForUser(
        userId:       userId,
        languageCode: currentLanguageCode,
      );
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void loadBookmarked() async {
    emit(DuaLoading());
    try {
      final duas = await repository.getBookmarkedForUser(
        userId:       userId,
        languageCode: currentLanguageCode,
      );
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  // ── Toggles ─────────────────────────────────────────────

  void toggleFavorite(DuasModel dua) async {
    try {
      await repository.toggleFavorite(dua, userId);
      // ── re-emit so BlocListener in favorite/bookmark pages fires ──
      emit(DuaLoaded([])); // lightweight signal — pages reload from DB
    } catch (e) {
      dua.isFavorite = !dua.isFavorite; // revert
      emit(DuaError(e.toString()));
    }
  }
  void toggleBookmark(DuasModel dua) async {
    try {
      await repository.toggleBookmark(dua, userId);
      // ── re-emit so BlocListener in favorite/bookmark pages fires ──
      emit(DuaLoaded([])); // lightweight signal — pages reload from DB
    } catch (e) {
      dua.isBookmarked = !dua.isBookmarked; // revert
      emit(DuaError(e.toString()));
    }
  }



  // ── Auth ─────────────────────────────────────────────────

  Future<void> onUserLogin(String realUserId) async {
    emit(DuaLoading());
    try {
      await repository.onUserLogin(realUserId);
      userId = realUserId;
      loadCategories();
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void onUserLogout() {
    userId = 'guest';
    loadCategories();
  }

  // ── Firestore Sync ───────────────────────────────────────

  Future<void> syncFromFirestore() async {
    emit(DuaLoading());
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncDuasFromFirestore();
      loadCategories();
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }
}