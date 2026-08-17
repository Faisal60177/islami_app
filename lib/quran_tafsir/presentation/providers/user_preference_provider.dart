import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_preference_provider.g.dart';

const _kDefaultTranslationIds = 'quran_default_translation_ids';
const _kDefaultReciterId = 'quran_default_reciter_id';
const _kArabicFontSize = 'quran_arabic_font_size';
const int _kFallbackTranslationId = 84;
const int _kTransliterationId = 57;
const int _kBengaliTranslationId = 161;
const int _kFallbackReciterId = 7;
const double _kFallbackFontSize = 26.0;

const List<int> _kDefaultTranslationIdsList = [
_kFallbackTranslationId,
_kTransliterationId,
_kBengaliTranslationId,
];

@riverpod
class QuranPreferences extends _$QuranPreferences {
@override
Future<QuranPreferenceState> build() async {
final prefs = await SharedPreferences.getInstance();

final savedTranslations = prefs.getStringList(_kDefaultTranslationIds);
final translationIds = savedTranslations != null
? savedTranslations.map(int.parse).toList()
    : _kDefaultTranslationIdsList;

final reciterId = prefs.getInt(_kDefaultReciterId) ?? _kFallbackReciterId;
final fontSize = prefs.getDouble(_kArabicFontSize) ?? _kFallbackFontSize;

return QuranPreferenceState(
translationIds: translationIds,
reciterId: reciterId,
arabicFontSize: fontSize,
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
reciterId: state.value?.reciterId ?? _kFallbackReciterId,
arabicFontSize: state.value?.arabicFontSize ?? _kFallbackFontSize,
),
);
}

Future<void> updateReciterId(int id) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setInt(_kDefaultReciterId, id);
state = AsyncData(
QuranPreferenceState(
translationIds:
state.value?.translationIds ?? _kDefaultTranslationIdsList,
reciterId: id,
arabicFontSize: state.value?.arabicFontSize ?? _kFallbackFontSize,
),
);
}

Future<void> updateArabicFontSize(double size) async {
final clamped = size.clamp(18.0, 40.0);
final prefs = await SharedPreferences.getInstance();
await prefs.setDouble(_kArabicFontSize, clamped);
state = AsyncData(
QuranPreferenceState(
translationIds:
state.value?.translationIds ?? _kDefaultTranslationIdsList,
reciterId: state.value?.reciterId ?? _kFallbackReciterId,
arabicFontSize: clamped,
),
);
}
}

class QuranPreferenceState {
final List<int> translationIds;
final int reciterId;
final double arabicFontSize;

const QuranPreferenceState({
required this.translationIds,
required this.reciterId,
this.arabicFontSize = _kFallbackFontSize,
});
}