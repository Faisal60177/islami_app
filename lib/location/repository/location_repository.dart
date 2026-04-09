import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:islamic_app/location/model/location_model.dart';
import 'package:islamic_app/location/services/timezone_service.dart'; // NEW

class LocationRepository {

  Future<LocationModel> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final lat = position.latitude;
    final lon = position.longitude;

    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    final city    = placemarks.first.locality ?? '';
    final country = placemarks.first.country ?? '';

    // ✅ Resolve timezone
    final timeZone = await TimezoneService.getTimezone(lat, lon);

    return LocationModel(
      latitude: lat,
      longitude: lon,
      city: city,
      country: country,
      timeZone: timeZone,
    );
  }

  Future<List<LocationModel>> searchLocation(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = "https://nominatim.openstreetmap.org/search"
        "?q=$encodedQuery&format=json&limit=5";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'islamic_app (your_email@gmail.com)',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as List;

    // ✅ Resolve timezone for each result (parallel)
    final futures = data.map((item) async {
      final lat = double.parse(item["lat"]);
      final lon = double.parse(item["lon"]);
      final timeZone = await TimezoneService.getTimezone(lat, lon);

      return LocationModel(
        latitude: lat,
        longitude: lon,
        city: item["display_name"],
        country: '',
        timeZone: timeZone,
      );
    });

    return Future.wait(futures);
  }
}