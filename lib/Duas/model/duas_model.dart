class DuasModel {
  final int id;
  final String category;
  final String arabic;
  final String transliteration;
  final Map<String, String> translation;
  final String reference;
  final String tags;
  final String? audioUrl;
  bool isFavorite;
  bool isBookmarked;

  DuasModel({
    required this.id,
    required this.category,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
    required this.tags,
    this.audioUrl,
    this.isFavorite = false,
    this.isBookmarked = false,
  });

  factory DuasModel.fromMap(Map<String, dynamic> map) {
    return DuasModel(
      id: map['id'],
      category: map['category'],
      arabic: map['arabic'],
      transliteration: map['transliteration'],
      translation: {
        'en': map['translation_en'] ?? '',
        'bn': map['translation_bn'] ?? '',
      },
      reference: map['reference'],
      tags: map['tags'],
      audioUrl: map['audio_url'],
      isFavorite: map['is_favorite'] == 1,
      isBookmarked: map['is_bookmarked'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'arabic': arabic,
      'transliteration': transliteration,
      'translation_en': translation['en'],
      'translation_bn': translation['bn'],
      'reference': reference,
      'tags': tags,
      'audio_url': audioUrl,
      'is_favorite': isFavorite ? 1 : 0,
      'is_bookmarked': isBookmarked ? 1 : 0,
    };
  }
}