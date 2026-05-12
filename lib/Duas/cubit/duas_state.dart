import 'package:muslim_app/Duas/model/duas_model.dart';

abstract class DuasState {}
class DuaInitial extends DuasState {}
class DuaLoading extends DuasState {}
class DuaLoaded extends DuasState {
  final List<DuasModel> duas;
  DuaLoaded(this.duas);
}
class DuaError extends DuasState {
  final String message;
  DuaError(this.message);
}