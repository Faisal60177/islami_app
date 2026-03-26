import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:islamic_app/location/model/location_model.dart';

class LocationRepository {
  // Fetch current GPS location
  Future<LocationModel> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = position.latitude;
    double lon = position.longitude;

    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    String city = placemarks.first.locality ?? "";
    String country = placemarks.first.country ?? "";

    return LocationModel(latitude: lat, longitude: lon, city: city, country: country);
  }

  /// Search location via OpenStreetMap API
  Future<List<LocationModel>> searchLocation(String query) async {
    final encodedQuery = Uri.encodeComponent(query); // ✅ added
    final url = "https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5";

    final response = await http
        .get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'islamic_app (your_email@gmail.com)', // ✅ added
        'Accept': 'application/json', // ✅ added
      },
    )
        .timeout(const Duration(seconds: 10)); // ✅ added

    final data = jsonDecode(response.body) as List;
    List<LocationModel> results = [];

    for (var item in data) {
      results.add(LocationModel(
        latitude: double.parse(item["lat"]),
        longitude: double.parse(item["lon"]),
        city: item["display_name"],
        country: "", // OSM does not separate country reliably here
      ));
    }
    return results;
  }
}