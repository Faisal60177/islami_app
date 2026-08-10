class CategoryModel {
  final int categoryId;
  final String categoryTitle;
  final String categoryIcon;

  CategoryModel({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIcon,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId:    map['category_id'],
      categoryTitle: map['category_title'] ?? '',
      categoryIcon:  map['category_icon']  ?? '',
    );
  }
}