import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/Duas/model/duas_model.dart';
import 'duas_state.dart';
import 'package:islamic_app/Duas/repository/duas_repository.dart';

class DuasCubit extends Cubit<DuasState> {
  final DuasRepository repository;
  DuasCubit(this.repository) : super(DuaInitial());

  /// 🔹 Load all duas
  void loadAllDuas() async {
    emit(DuaLoading());
    final duas = await repository.getAllDuas();
    emit(DuaLoaded(duas));
  }

  /// 🔹 Load duas filtered by category
  void loadDuasByCategory(String category) async {
    emit(DuaLoading());
    final allDuas = await repository.getAllDuas();
    final filtered = allDuas.where((d) => d.category == category).toList();
    emit(DuaLoaded(filtered));
  }

  /// 🔹 Toggle favorite for a dua
  void toggleFavorite(DuasModel dua) async {
    await repository.toggleFavorite(dua);
    // Reload duas for current state
    if (state is DuaLoaded) {
      final current = (state as DuaLoaded).duas;
      emit(DuaLoaded(List.from(current)));
    } else {
      loadAllDuas();
    }
  }

  /// 🔹 Toggle bookmark for a dua
  void toggleBookmark(DuasModel dua) async {
    await repository.toggleBookmark(dua);
    if (state is DuaLoaded) {
      final current = (state as DuaLoaded).duas;
      emit(DuaLoaded(List.from(current)));
    } else {
      loadAllDuas();
    }
  }

  /// 🔹 Load only favorites
  void loadFavorites() async {
    emit(DuaLoading());
    final allDuas = await repository.getAllDuas();
    final favorites = allDuas.where((d) => d.isFavorite).toList();
    emit(DuaLoaded(favorites));
  }

  /// 🔹 Load only bookmarked
  void loadBookmarked() async {
    emit(DuaLoading());
    final allDuas = await repository.getAllDuas();
    final bookmarks = allDuas.where((d) => d.isBookmarked).toList();
    emit(DuaLoaded(bookmarks));
  }
  /// 🔹 🔥 Firestore sync → SQLite → UI
  Future<void> syncFromFirestore() async {
    try {
      // Sync categories & duas from Firestore
      await repository.syncCategoriesFromFirestore();
      await repository.syncDuasFromFirestore();

      // Reload all duas in UI after sync
      loadAllDuas();

      // Optional debug
      print("🔥 Firestore sync completed");
    } catch (e) {
      print("❌ Firestore sync error: $e");
    }
  }

}