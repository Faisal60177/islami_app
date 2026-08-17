import '../../domain/entities/juz.dart';

class JuzModel extends Juz {
  const JuzModel({
    required super.juzNumber,
    required super.versesCount,
    required super.firstVerseKey,
    required super.lastVerseKey,
  });

  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      juzNumber: json['juz_number'] as int,
      versesCount: json['verses_count'] as int? ?? 0,
      firstVerseKey: json['first_verse_key'] as String? ?? '',
      lastVerseKey: json['last_verse_key'] as String? ?? '',
    );
  }
}