import '../../domain/entities/translation_resource.dart';

class TranslationResourceModel extends TranslationResource {
  const TranslationResourceModel({
    required super.id,
    required super.name,
    required super.authorName,
    required super.languageName,
  });

  factory TranslationResourceModel.fromJson(Map<String, dynamic> json) {
    return TranslationResourceModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
    );
  }
}
