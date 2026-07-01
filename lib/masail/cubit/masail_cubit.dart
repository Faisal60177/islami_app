import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/masail_model.dart';
import '../repository/masail_repository.dart';
import 'masail_state.dart';

class MasailCubit extends Cubit<MasailState> {
  final MasailRepository repository;
  String userId;
  String currentLanguageCode;

  MasailCubit(this.repository)
      : userId = 'guest',
        currentLanguageCode = 'en',
        super(MasailInitial());

  // ── Language update from Settings ──────────────────────
  // Call this whenever user changes language in settings
  void updateLanguage(String languageCode) {
    currentLanguageCode = languageCode;
  }

  Future<void> loadCategoriesIfEmpty() async {
    try {
      final categories = await repository.getAllCategories(currentLanguageCode);
      final masail = await repository.getAllMasail(
        languageCode: currentLanguageCode,
        userId:       userId,
      );
      emit(MasailCategoriesLoaded(categories));
      emit(MasailLoaded(masail));

      _syncSilently();
    } catch (e) {
      emit(MasailError(e.toString()));
    }
  }



  Future<void> _syncSilently() async {
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncMasailFromFirestore();
      final categories = await repository.getAllCategories(currentLanguageCode);
      final masail = await repository.getAllMasail(
        languageCode: currentLanguageCode,
        userId:       userId,
      );

      emit(MasailCategoriesLoaded(categories));
      emit(MasailLoaded(masail));
    } catch (_) {
    }
  }

  // ── Categories ──────────────────────────────────────────

  void loadCategories() async {
    emit(MasailLoading());
    try {
      final categories =
      await repository.getAllCategories(currentLanguageCode);
      emit(MasailCategoriesLoaded(categories));
    } catch (e) {
      emit(MasailError(e.toString()));
    }
  }

  // ── Masail ──────────────────────────────────────────────

  void loadMasailByCategory(int categoryId) async {
    emit(MasailLoading());
    try {
      final masail = await repository.getMasailByCategory(
        categoryId:   categoryId,
        languageCode: currentLanguageCode,
        userId:       userId,
      );
      emit(MasailLoaded(masail));
    } catch (e) {
      emit(MasailError(e.toString()));
    }
  }

  void loadBookmarked() async {
    emit(MasailLoading());
    try {
      final masail = await repository.getBookmarkedForUser(
        userId:       userId,
        languageCode: currentLanguageCode,
      );
      emit(MasailLoaded(masail));
    } catch (e) {
      emit(MasailError(e.toString()));
    }
  }

  // ── Bookmark toggle ─────────────────────────────────────

  void toggleBookmark(MasailModel masail) async {
    try {
      await repository.toggleBookmark(masail, userId);
      // ── re-emit so BlocListener on bookmark page fires ──
      emit(MasailLoaded([])); // lightweight signal — page reloads from DB
    } catch (e) {
      masail.isBookmarked = !masail.isBookmarked; // revert on failure
      emit(MasailError(e.toString()));
    }
  }

  // ── Auth ─────────────────────────────────────────────────

  Future<void> onUserLogin(String realUserId) async {
    emit(MasailLoading());
    try {
      await repository.onUserLogin(realUserId);
      userId = realUserId;
      loadCategories();
    } catch (e) {
      emit(MasailError(e.toString()));
    }
  }

  void onUserLogout() {
    userId = 'guest';
    loadCategories();
  }

  // ── Firestore Sync ───────────────────────────────────────

  Future<void> syncFromFirestore() async {
    emit(MasailLoading());
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncMasailFromFirestore();
      loadCategories();
    } catch (e) {
      emit(MasailError(e.toString()));
    }
  }
}