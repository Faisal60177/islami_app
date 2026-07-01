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

  Future<void> loadCategoriesIfEmpty() async {
    try {
      final categories =
      await repository.getAllCategories(currentLanguageCode);

      if (categories.isEmpty) {
        // ✅ Try sync only if internet available — silently skip if not
        emit(InspirationLoading());
        try {
          await repository.syncCategoriesFromFirestore();
          await repository.syncInspirationsFromFirestore();
        } catch (_) {
          // ✅ No internet — skip silently, show empty state
          emit(InspirationCategoriesLoaded([]));
          emit(InspirationLoaded([]));
          return;
        }
        final refreshed =
        await repository.getAllCategories(currentLanguageCode);
        final inspirations = await repository.getAllInspirations(
          languageCode: currentLanguageCode,
          userId:       userId,
        );
        emit(InspirationCategoriesLoaded(refreshed));
        emit(InspirationLoaded(inspirations));
      } else {
        final inspirations = await repository.getAllInspirations(
          languageCode: currentLanguageCode,
          userId:       userId,
        );
        emit(InspirationCategoriesLoaded(categories));
        emit(InspirationLoaded(inspirations));
        _syncSilently();
      }
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }

  // Syncs Firestore in background without touching UI state
  Future<void> _syncSilently() async {
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncInspirationsFromFirestore();
      // Refresh data after sync — still no loading spinner
      final categories =
      await repository.getAllCategories(currentLanguageCode);
      final inspirations = await repository.getAllInspirations(
        languageCode: currentLanguageCode,
        userId:       userId,
      );
      emit(InspirationCategoriesLoaded(categories));
      emit(InspirationLoaded(inspirations));
    } catch (_) {
      // Silent — don't show error for background sync failures
    }
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
    // ✅ NO mutation here — UI already did setState
    try {
      await repository.toggleFavorite(inspiration, userId);
    } catch (e) {
      inspiration.isFavorite = !inspiration.isFavorite; // revert only on error
      emit(InspirationError(e.toString()));
    }
  }

  void toggleBookmark(InspirationModel inspiration) async {
    // ✅ NO mutation here — UI already did setState
    try {
      await repository.toggleBookmark(inspiration, userId);
    } catch (e) {
      inspiration.isBookmarked = !inspiration.isBookmarked; // revert only on error
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

  // ── Firestore Sync (explicit full sync with spinner) ─────
  Future<void> syncFromFirestore() async {
    emit(InspirationLoading());
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncInspirationsFromFirestore();
      loadCategories();
    } catch (e) {
      emit(InspirationError(e.toString()));
    }
  }
}