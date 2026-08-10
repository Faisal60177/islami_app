import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_preference_provider.g.dart';

const _kDefaultTranslationIds = 'quran_default_translation_ids';
const _kDefaultReciterId = 'quran_default_reciter_id';

@riverpod
class QuranPreferences extends _$QuranPreferences {
  @override
  Future<QuranPreferenceState> build() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTranslations = prefs.getStringList(_kDefaultTranslationIds);
    final translationIds = savedTranslations != null
        ? savedTranslations.map(int.parse).toList()
        : <int>[131]; // fallback default: Saheeh International

    final reciterId = prefs.getInt(_kDefaultReciterId) ?? 7; // Alafasy default

    return QuranPreferenceState(
      translationIds: translationIds,
      reciterId: reciterId,
    );
  }

  Future<void> updateTranslationIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kDefaultTranslationIds,
      ids.map((e) => e.toString()).toList(),
    );
    state = AsyncData(
      QuranPreferenceState(
        translationIds: ids,
        reciterId: state.value?.reciterId ?? 7,
      ),
    );
  }

  Future<void> updateReciterId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDefaultReciterId, id);
    state = AsyncData(
      QuranPreferenceState(
        translationIds: state.value?.translationIds ?? [131],
        reciterId: id,
      ),
    );
  }
}

class QuranPreferenceState {
  final List<int> translationIds;
  final int reciterId;

  const QuranPreferenceState({
    required this.translationIds,
    required this.reciterId,
  });
}
