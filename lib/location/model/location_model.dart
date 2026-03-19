class LocationModel {
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  // copyWith for immutability
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  // Optional: JSON methods for future API or local storage
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      city: json['city'],
      country: json['country'],
    );
  }
}