import '../model/inspiration_model.dart';
import '../model/inspiration_category_model.dart';

abstract class InspirationState {}

class InspirationInitial extends InspirationState {}
class InspirationLoading  extends InspirationState {}

class InspirationError extends InspirationState {
  final String message;
  InspirationError(this.message);
}

class InspirationLoaded extends InspirationState {
  final List<InspirationModel> inspirations;
  InspirationLoaded(this.inspirations);
}

class InspirationCategoriesLoaded extends InspirationState {
  final List<InspirationCategoryModel> categories;
  InspirationCategoriesLoaded(this.categories);
}