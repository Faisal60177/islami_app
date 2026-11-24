class MasailModel {
  final int id;
  final int categoryId;
  final String categoryTitle;
  final String? arabic;       // optional — not all masail have Arabic text
  final String question;
  final String answer;
  final String reference;
  final String? madhab;       // optional — e.g. Hanafi, Shafi'i, Maliki, Hanbali
  bool isBookmarked;

  MasailModel({
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    this.arabic,
    required this.question,
    required this.answer,
    required this.reference,
    this.madhab,
    this.isBookmarked = false,
  });

  factory MasailModel.fromMap(Map<String, dynamic> map) {
    return MasailModel(
      id:            map['id'],
      categoryId:    map['category_id']    ?? 0,
      categoryTitle: map['category_title'] ?? '',
      arabic:        map['arabic'],                     // nullable — no fallback needed
      question:      map['question']       ?? '',
      answer:        map['answer']         ?? '',
      reference:     map['reference']      ?? '',
      madhab:        map['madhab'],                     // nullable — no fallback needed
      isBookmarked:  map['is_bookmarked'] == 1,         // SQLite stores bool as 0/1
    );
  }
}