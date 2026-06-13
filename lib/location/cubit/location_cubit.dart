import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/location/services/default_location.dart';
import 'package:muslim_app/location/services/permission_service.dart';
import 'package:muslim_app/location/services/location_storage.dart';
import 'package:muslim_app/location/model/location_model.dart';
import 'package:muslim_app/location/repository/location_repository.dart';
import 'location_state.dart';


class LocationCubit extends Cubit<LocationState> {
  final LocationRepository repository;
  final LocationStorage storage;
  final PermissionService permissionService;

  LocationCubit(this.repository, this.storage, this.permissionService)
      : super(LocationInitial());

  /// Load last saved location from SharedPreferences
  /// If nothing saved, save the default location once
  Future<void> loadSavedLocation() async {
    final saved = await storage.getSavedLocation();

    if (saved != null) {
      // Last saved location found → emit it
      print("Last Saved Location Loaded:");
      print("Latitude: ${saved.latitude}");
      print("Longitude: ${saved.longitude}");
      print("Time Zone: ${saved.timeZone}");
      print("City: ${saved.city}");
      print("Country: ${saved.country}");

      emit(LocationLoaded(saved));
    } else {
      // First app run → save default location
      final defaultLocation = DefaultLocation.location;
      await storage.saveLocation(defaultLocation);

      print("Default Location Saved (first run):");
      print("Latitude: ${defaultLocation.latitude}");
      print("Longitude: ${defaultLocation.longitude}");
      print("Time Zone: ${defaultLocation.timeZone}");
      print("City: ${defaultLocation.city}");
      print("Country: ${defaultLocation.country}");

      emit(LocationLoaded(defaultLocation));
    }
  }

  /// Get GPS location → replace last saved location
  Future<void> getGPSLocation() async {
    emit(LocationLoading());

    bool allowed = await permissionService.requestLocationPermission();
    if (!allowed) {
      emit(LocationPermissionDenied());
      return;
    }

    try {
      final location = await repository.getCurrentLocation();
      emit(LocationLoaded(location));
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  /// Search location
  Future<void> selectLocation(LocationModel location) async {

    emit(LocationLoaded(location));
  }

  /// Autocomplete search
  Future<void> searchLocation(String query) async {
    emit(LocationLoading());

    try {
      final results = await repository.searchLocation(query);
      emit(LocationSearchResults(results));
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  /// Explicitly save the currently displayed location
  Future<void> saveCurrentLocation() async {
    if (state is LocationLoaded) {
      final location = (state as LocationLoaded).location;
      await storage.saveLocation(location);

      print("Location Saved (explicit):");
      print(location.latitude);
      print(location.longitude);
      print(location.timeZone);
      print(location.city);
      print(location.country);
    }
  }

}
