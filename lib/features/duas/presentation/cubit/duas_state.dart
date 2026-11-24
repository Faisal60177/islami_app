import 'package:muslim_app/features/duas/data/models/dua_model.dart';
import 'package:muslim_app/features/duas/data/models/category_model.dart';

abstract class DuasState {}

class DuaInitial    extends DuasState {}
class DuaLoading    extends DuasState {}
class DuaError      extends DuasState {
  final String message;
  DuaError(this.message);
}

class DuaLoaded extends DuasState {
  final List<DuasModel> duas;
  DuaLoaded(this.duas);
}

class CategoriesLoaded extends DuasState {
  final List<CategoryModel> categories;
  CategoriesLoaded(this.categories);
}