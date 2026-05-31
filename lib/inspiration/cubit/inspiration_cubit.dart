import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/inspiration_model.dart';
import '../repository/inspiration_repository.dart';
import 'inspiration_state.dart';

class InspirationCubit extends Cubit<InspirationState> {
  final InspirationRepository repository;
  String userId;
  String currentLanguageCode;

  InspirationCubit(this.repository)
      : userId = 'guest',
        currentLanguageCode = 'en',
        super(InspirationInitial());

  void updateLanguage(String languageCode) {
    currentLanguageCode = languageCode;
  }

  // ── Categories ──────────────────────────────────────────

  void loadCategories() async {
    emit(InspirationLoading());
    try {
      final categories =
      await repository.getAllCategories(currentLanguageCode);
      emit(InspirationCategoriesLoaded(categories));
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  // ── Inspirations ────────────────────────────────────────

  void loadInspirationsByCategory(int categoryId) async {
    emit(InspirationLoading());
    try {
      final inspirations = await repository.getInspirationsByCategory(
        categoryId:   categoryId,
        languageCode: currentLanguageCode,
        userId:       userId,
      );
      emit(InspirationLoaded(inspirations));
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  void loadAllInspirations() async {
    emit(InspirationLoading());
    try {
      final inspirations = await repository.getAllInspirations(
        languageCode: currentLanguageCode,
        userId:       userId,
      );
      emit(InspirationLoaded(inspirations));
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  void loadFavorites() async {
    emit(InspirationLoading());
    try {
      final inspirations = await repository.getFavoritesForUser(
        userId:       userId,
        languageCode: currentLanguageCode,
      );
      emit(InspirationLoaded(inspirations));
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  void loadBookmarked() async {
    emit(InspirationLoading());
    try {
      final inspirations = await repository.getBookmarkedForUser(
        userId:       userId,
        languageCode: currentLanguageCode,
      );
      emit(InspirationLoaded(inspirations));
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  // ── Toggles ─────────────────────────────────────────────

  void toggleFavorite(InspirationModel inspiration) async {
    inspiration.isFavorite = !inspiration.isFavorite;
    try {
      await repository.toggleFavorite(inspiration, userId);
      emit(InspirationLoaded([]));
    } catch (e) {
      inspiration.isFavorite = !inspiration.isFavorite;
      emit(InspirationError(e.toString()));
    }
  }

  void toggleBookmark(InspirationModel inspiration) async {
    inspiration.isBookmarked = !inspiration.isBookmarked;
    try {
      await repository.toggleBookmark(inspiration, userId);
      emit(InspirationLoaded([]));
    } catch (e) {
      inspiration.isBookmarked = !inspiration.isBookmarked;
      emit(InspirationError(e.toString()));
    }
  }

  // ── Auth ─────────────────────────────────────────────────

  Future<void> onUserLogin(String realUserId) async {
    emit(InspirationLoading());
    try {
      await repository.onUserLogin(realUserId);
      userId = realUserId;
      loadCategories();
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  void onUserLogout() {
    userId = 'guest';
    loadCategories();
  }

  // ── Firestore Sync ───────────────────────────────────────
  // ✅ Call this FIRST before loadCategories
  // Without sync, SQLite is empty → nothing shows

  Future<void> syncFromFirestore() async {
    emit(InspirationLoading());
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncInspirationsFromFirestore();
      // After sync → load categories → listener loads inspirations
      loadCategories();
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }
}