class MasailCategoryModel {
  final int categoryId;
  final String categoryTitle;
  final String categoryIcon; // optional field — empty string if not provided

  MasailCategoryModel({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIcon,
  });

  factory MasailCategoryModel.fromMap(Map<String, dynamic> map) {
    return MasailCategoryModel(
      categoryId:    map['category_id'],
      categoryTitle: map['category_title'] ?? '',
      categoryIcon:  map['category_icon']  ?? '',
    );
  }
}