import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:islamic_app/location/model/location_model.dart';

class LocationStorage {
  Future<void> saveLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("lat", location.latitude);
    await prefs.setDouble("lon", location.longitude);
    await prefs.setString("city", location.city);
    await prefs.setString("country", location.country);
  }

  Future<LocationModel?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble("lat");
    double? lon = prefs.getDouble("lon");
    String? city = prefs.getString("city");
    String? country = prefs.getString("country");

    if (lat == null || lon == null) return null;

    return LocationModel(
      latitude: lat,
      longitude: lon,
      city: city ?? "",
      country: country ?? "",
    );
  }
}