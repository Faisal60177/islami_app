import 'package:muslim_app/location/model/location_model.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final LocationModel location;
  LocationLoaded(this.location);
}

class LocationSearchResults extends LocationState {
  final List<LocationModel> results;
  LocationSearchResults(this.results);
}

class LocationPermissionDenied extends LocationState {}

class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}