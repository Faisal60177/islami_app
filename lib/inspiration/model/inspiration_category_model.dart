class InspirationCategoryModel {
  final int categoryId;
  final String categoryTitle; // resolved language via COALESCE
  final String categoryIcon;  // emoji or icon name — optional

  InspirationCategoryModel({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIcon,
  });

  factory InspirationCategoryModel.fromMap(Map<String, dynamic> map) {
    return InspirationCategoryModel(
      categoryId:    map['category_id'],
      categoryTitle: map['category_title'] ?? '',
      categoryIcon:  map['category_icon']  ?? '',
    );
  }
}