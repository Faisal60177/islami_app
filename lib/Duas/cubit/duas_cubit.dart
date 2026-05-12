import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/Duas/model/duas_model.dart';
import 'duas_state.dart';
import 'package:muslim_app/Duas/repository/duas_repository.dart';

class DuasCubit extends Cubit<DuasState> {
  final DuasRepository repository;
  String userId;

  DuasCubit(this.repository) : userId = 'guest', super(DuaInitial());

  /// ── Content loads ────────────────────────────────────
  void loadAllDuas() async {
    emit(DuaLoading());
    try {
      final duas = await repository.getAllDuas();
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void loadDuasByCategory(String categoryTitle) async {
    emit(DuaLoading());
    try {
      final duas = await repository.getDuasByCategory(categoryTitle);
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void loadFavorites() async {
    emit(DuaLoading());
    try {
      final duas = await repository.getFavoritesForUser(userId);
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void loadBookmarked() async {
    emit(DuaLoading());
    try {
      final duas = await repository.getBookmarkedForUser(userId);
      emit(DuaLoaded(duas));
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  /// ── Toggles ──────────────────────────────────────────
  void toggleFavorite(DuasModel dua) async {
    try {
      await repository.toggleFavorite(dua, userId);
      // ✅ no emit needed — UI already updated optimistically
    } catch (e) {
      // ✅ revert on error
      dua.isFavorite = !dua.isFavorite;
      emit(DuaError(e.toString()));
    }
  }

  void toggleBookmark(DuasModel dua) async {
    try {
      await repository.toggleBookmark(dua, userId);
    } catch (e) {
      dua.isBookmarked = !dua.isBookmarked;
      emit(DuaError(e.toString()));
    }
  }

  /// ── Auth events ──────────────────────────────────────
  Future<void> onUserLogin(String realUserId) async {
    emit(DuaLoading());
    try {
      await repository.onUserLogin(realUserId);
      userId = realUserId;
      loadAllDuas();
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }

  void onUserLogout() {
    userId = 'guest';
    loadAllDuas();
  }

  /// ── Firestore sync ───────────────────────────────────
  Future<void> syncFromFirestore() async {
    emit(DuaLoading());
    try {
      await repository.syncCategoriesFromFirestore();
      await repository.syncDuasFromFirestore();
      loadAllDuas();
    } catch (e) {
      emit(DuaError(e.toString()));
    }
  }
}