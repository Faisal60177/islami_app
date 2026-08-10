import 'package:timeago/timeago.dart';

import '../../domain/entities/chapter.dart';

class ChapterModel extends Chapter{
  const ChapterModel({
    required super.id,
    required super.nameSimple,
    required super.nameArabic,
    required super.translatedName,
    required super.versesCount,
    required super.revelationPlace,
    required super.bismillahPre,
});

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] as int,
      nameSimple: json['name_simple'] as String,
      nameArabic: json['name_arabic'] as String,
      translatedName:
      (json['translated_name'] as Map<String, dynamic>)['name'] as String,
      versesCount: json['verses_count'] as int,
      revelationPlace: json['revelation_place'] as String,
      bismillahPre: json['bismillah_pre'] as bool? ?? false,
    );
  }

}