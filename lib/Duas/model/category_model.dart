class CategoryModel {
  final String category;
  final String categoryTitle;
  final String categoryIcon;

  CategoryModel({
    required this.category,
    required this.categoryTitle,
    required this.categoryIcon,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      category: map['category'],
      categoryTitle: map['category_title'],
      categoryIcon: map['category_icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'category_title': categoryTitle,
      'category_icon': categoryIcon,
    };
  }
}