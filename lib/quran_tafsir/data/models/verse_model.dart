import '../../domain/entities/verse.dart';

class VerseModel extends Verse {
  const VerseModel({
    required super.id,
    required super.verseKey,
    required super.verseNumber,
    required super.chapterId,
    required super.textUthmani,
    required super.translations,
    super.words,
    super.audio,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    final verseKey = json['verse_key'] as String;
    final chapterId =
        _asInt(json['chapter_id']) as int? ?? int.parse(verseKey.split(':').first);

    return VerseModel(
      id: _asInt(json['id']) ?? 0,
      verseKey: verseKey,
      verseNumber: _asInt(json['verse_number']) ?? 0,
      chapterId: chapterId,
      textUthmani: json['text_uthmani'] as String? ?? '',
      translations: _parseTranslations(json['translations']),
      words: _parseWords(json['words']),
      audio: _parseAudio(json['audio']),
    );
  }

  static List<VerseTranslation> _parseTranslations(dynamic raw){
    if(raw == null) return [];
    final list = raw as List<dynamic>;
    return list.map((t){
      final map = t as Map<String, dynamic>;
      return VerseTranslation(
        resourceId: _asInt(map['resource_id']) ?? 0,
          resourceName: map['resource_name'] as String? ?? '',

          text: map['text'] as String? ?? '',);
    }).toList();
  }

  static List<Word> _parseWords(dynamic raw) {
    if (raw == null) return [];
    final list = raw as List<dynamic>;
    return list.map((w) {
      final map = w as Map<String, dynamic>;
      final position = _asInt(map['position']) ??
          _positionFromLocation(map['location'] as String?);
      return Word(
        position: position,
        textUthmani: map['text_uthmani'] as String? ?? '',
        charType: map['char_type_name'] as String? ?? 'word',
      );
    }).toList();
  }

  static int _positionFromLocation(String? location) {
    if (location == null) return 0;
    final parts = location.split(':');
    return int.tryParse(parts.last) ?? 0;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static VerseAudio? _parseAudio(dynamic raw){
    if(raw == null) return null;
    final map = raw as Map<String, dynamic>;
    final rawUrl = map['url'] as String?;
    if(rawUrl == null || rawUrl.isEmpty) return null;

    return VerseAudio(url: _normalizeAudioUrl(rawUrl),
      segments: _parseSegments(map['segments']),   // ← নতুন লাইন
    );
  }

  static String _normalizeAudioUrl(String rawUrl){
    const baseUrl = 'https://verses.quran.foundation/';
    if(rawUrl.startsWith('http://') || rawUrl.startsWith('https://')){
      return rawUrl;
    }
    return baseUrl + rawUrl;
  }

  factory VerseModel.fromEntity(Verse verse) => VerseModel(
    id: verse.id,
    verseKey: verse.verseKey,
    verseNumber: verse.verseNumber,
    chapterId: verse.chapterId,
    textUthmani: verse.textUthmani,
    translations: verse.translations,
    words: verse.words,
    audio: verse.audio,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verse_key': verseKey,
      'verse_number': verseNumber,
      'chapter_id': chapterId,
      'text_uthmani': textUthmani,
      'translations': translations
          .map((t) => {
        'resource_id': t.resourceId,
        'resource_name': t.resourceName,
        'text': t.text,
      })
          .toList(),
      'words': words
          .map((w) => {
        'position': w.position,
        'text_uthmani': w.textUthmani,
        'char_type_name': w.charType,
      })
          .toList(),
      'audio': audio == null
          ? null
          : {
        'url': audio!.url,
        'segments': audio!.segments
            .map((s) => [s.wordStart, s.wordEnd, s.startMs, s.endMs])
            .toList(),
      },
    };
  }

  static List<AudioSegment> _parseSegments(dynamic raw) {
    if (raw == null) return [];
    final list = raw as List<dynamic>;
    return list.map((s) {
      final seg = (s as List<dynamic>).map((e) => _asInt(e) ?? 0).toList();
      return AudioSegment(
        wordStart: seg[0],
        wordEnd: seg[1],
        startMs: seg[2],
        endMs: seg[3],
      );
    }).toList();
  }

}