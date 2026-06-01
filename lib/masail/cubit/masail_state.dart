import '../model/masail_model.dart';
import '../model/masail_category_model.dart';

abstract class MasailState {}

class MasailInitial          extends MasailState {}
class MasailLoading          extends MasailState {}
class MasailError            extends MasailState {
  final String message;
  MasailError(this.message);
}

class MasailLoaded extends MasailState {
  final List<MasailModel> masail;
  MasailLoaded(this.masail);
}

class MasailCategoriesLoaded extends MasailState {
  final List<MasailCategoryModel> categories;
  MasailCategoriesLoaded(this.categories);
}