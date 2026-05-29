class InspirationModel {
  final int id;
  final int categoryId;
  final String categoryTitle;  // resolved language via JOIN
  final String title;          // resolved language — short label
  final String quoteText;      // resolved language — main quote body
  final String? reference;     // optional — "Quran 94:6", null = hide
  final String? author;        // optional — "Imam Abu Hanifa", null = hide
  bool isFavorite;
  bool isBookmarked;

  InspirationModel({
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    required this.title,
    required this.quoteText,
    this.reference,
    this.author,
    this.isFavorite = false,
    this.isBookmarked = false,
  });

  factory InspirationModel.fromMap(Map<String, dynamic> map) {
    return InspirationModel(
      id:            map['id'],
      categoryId:    map['category_id'] ?? 0,
      categoryTitle: map['category_title'] ?? '',
      title:         map['title'] ?? '',
      quoteText:     map['quote_text'] ?? '',
      reference:     map['reference'],       // null if not provided
      author:        map['author'],          // null if not provided
      isFavorite:    map['is_favorite'] == 1,
      isBookmarked:  map['is_bookmarked'] == 1,
    );
  }
}