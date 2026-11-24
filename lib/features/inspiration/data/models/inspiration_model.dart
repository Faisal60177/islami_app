class InspirationModel {
  final int id;
  final int categoryId;
  final String categoryTitle;
  final String title;
  final String quoteText;
  final String? reference;
  final String? author;
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
      reference:     map['reference'],
      author:        map['author'],
      isFavorite:    map['is_favorite'] == 1,
      isBookmarked:  map['is_bookmarked'] == 1,
    );
  }
}