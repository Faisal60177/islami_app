import '../../domain/entities/verse.dart';

class VerseModel extends Verse {
  const VerseModel({
    required super.id,
    required super.verseKey,
    required super.verseNumber,
    required super.chapterId,
    required super.textUthmani,
    required super.translations,
    super.audio,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    final verseKey = json['verse_key'] as String;
    final chapterId =
        json['chapter_id'] as int? ?? int.parse(verseKey.split(':').first);

    return VerseModel(
      id: json['id'] as int,
      verseKey: verseKey,
      verseNumber: json['verse_number'] as int,
      chapterId: chapterId,
      textUthmani: json['text_uthmani'] as String? ?? '',
      translations: _parseTranslations(json['translations']),
      audio: _parseAudio(json['audio']),
    );
  }

  static List<VerseTranslation> _parseTranslations(dynamic raw){
    if(raw == null) return [];
    final list = raw as List<dynamic>;
    return list.map((t){
      final map = t as Map<String, dynamic>;
      return VerseTranslation(
          resourceId: map['resource_id'] as int,
          resourceName: map['resource_name'] as String? ?? '',

          text: map['text'] as String? ?? '',);
    }).toList();
  }

  static VerseAudio? _parseAudio(dynamic raw){
    if(raw == null) return null;
    final map = raw as Map<String, dynamic>;
    final rawUrl = map['url'] as String?;
    if(rawUrl == null || rawUrl.isEmpty) return null;

    return VerseAudio(url: _normalizeAudioUrl(rawUrl));
  }

  static String _normalizeAudioUrl(String rawUrl){
    const baseUrl = 'https://verses.quran.foundation/';
    if(rawUrl.startsWith('http://') || rawUrl.startsWith('https://')){
      return rawUrl;
    }
    return baseUrl + rawUrl;
  }

}