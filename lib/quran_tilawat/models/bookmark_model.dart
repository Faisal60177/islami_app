class BookmarkModel {
  final int pageNumber;
  final int surahNumber;
  final String surahNameAr;
  final String surahNameEn;
  final DateTime savedAt;

  const BookmarkModel({
    required this.pageNumber,
    required this.surahNumber,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() => {
    'pageNumber': pageNumber,
    'surahNumber': surahNumber,
    'surahNameAr': surahNameAr,
    'surahNameEn': surahNameEn,
    'savedAt': savedAt.toIso8601String(),
  };

  factory BookmarkModel.fromMap(Map<String, dynamic> m) => BookmarkModel(
    pageNumber: m['pageNumber'],
    surahNumber: m['surahNumber'],
    surahNameAr: m['surahNameAr'],
    surahNameEn: m['surahNameEn'],
    savedAt: DateTime.parse(m['savedAt']),
  );
}