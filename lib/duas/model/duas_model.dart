class DuasModel {
  final int id;
  final int categoryId;
  final String categoryTitle;
  final String arabic;
  final String title;
  final String transliteration;
  final String translationText;
  final String reference;
  final String? description;
  final String? audioUrl;
  bool isFavorite;
  bool isBookmarked;

  DuasModel({
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    required this.arabic,
    required this.title,
    required this.transliteration,
    required this.translationText,
    required this.reference,
    this.description,
    this.audioUrl,
    this.isFavorite = false,
    this.isBookmarked = false,
  });

  factory DuasModel.fromMap(Map<String, dynamic> map) {
    return DuasModel(
      id:              map['id'],
      categoryId:      map['category_id'] ?? 0,
      categoryTitle:   map['category_title'] ?? '',
      arabic:          map['arabic'] ?? '',
      title:           map['title'] ?? '',
      transliteration: map['transliteration'] ?? '',
      translationText: map['translation_text'] ?? '',
      reference:       map['reference'] ?? '',
      description:     map['description'],
      audioUrl:        map['audio_url'],
      isFavorite:      map['is_favorite'] == 1,
      isBookmarked:    map['is_bookmarked'] == 1,
    );
  }
}