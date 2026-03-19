import 'package:islamic_app/Duas/model/duas_model.dart';

abstract class DuasState {}
class DuaInitial extends DuasState {}
class DuaLoading extends DuasState {}
class DuaLoaded extends DuasState {
  final List<DuasModel> duas;
  DuaLoaded(this.duas);
}