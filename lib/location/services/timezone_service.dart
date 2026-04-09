// lib/location/services/timezone_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class _Zone {
  final double minLat, maxLat, minLng, maxLng;
  final String tz;
  const _Zone(this.minLat, this.maxLat, this.minLng, this.maxLng, this.tz);
}

class TimezoneService {
  /// Returns IANA timezone string e.g. "America/New_York", "Asia/Dhaka"
  /// Primary: free timeapi.io API (accurate for entire world)
  /// Fallback: coordinate bounding-box lookup (works offline)
  static Future<String> getTimezone(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://timeapi.io/api/TimeZone/coordinate?latitude=$lat&longitude=$lng',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tz = data['timeZone'] as String?;
        if (tz != null && tz.isNotEmpty) return tz;
      }
    } catch (_) {}

    // Fallback: coordinate-based lookup
    return _coordinateFallback(lat, lng);
  }

  // ── Coordinate bounding-box fallback ────────────────────────────────────
  // Each entry: [minLat, maxLat, minLng, maxLng, 'IANA/Timezone']
  // Ordered roughly by population/usage so common ones resolve faster.
  // For countries that span multiple zones, sub-regions are listed first.

  static String _coordinateFallback(double lat, double lng) {
    for (final z in _zones) {
      if (lat >= z.minLat && lat <= z.maxLat && lng >= z.minLng && lng <= z.maxLng) {
        return z.tz;
      }
    }
    // Last-resort: pure longitude math
    final offset = (lng / 15).round().clamp(-12, 14);
    return _utcFallback[offset] ?? 'UTC';
  }

  static const _utcFallback = {
    -12: 'Etc/GMT+12', -11: 'Pacific/Pago_Pago',
    -10: 'Pacific/Honolulu', -9: 'America/Anchorage',
    -8: 'America/Los_Angeles', -7: 'America/Denver',
    -6: 'America/Chicago', -5: 'America/New_York',
    -4: 'America/Halifax', -3: 'America/Sao_Paulo',
    -2: 'Atlantic/South_Georgia', -1: 'Atlantic/Azores',
    0: 'Europe/London', 1: 'Europe/Paris',
    2: 'Europe/Cairo', 3: 'Asia/Riyadh',
    4: 'Asia/Dubai', 5: 'Asia/Karachi',
    6: 'Asia/Dhaka', 7: 'Asia/Bangkok',
    8: 'Asia/Shanghai', 9: 'Asia/Tokyo',
    10: 'Australia/Sydney', 11: 'Pacific/Noumea',
    12: 'Pacific/Auckland', 13: 'Pacific/Apia',
    14: 'Pacific/Kiritimati', 15: 'Asia/Kuching',
  };

  // ── Zone table ──────────────────────────────────────────────────────────
  // Each _Zone: (minLat, maxLat, minLng, maxLng, 'IANA/Timezone')
  // Sub-regions listed before their parent country to get the right match.
  static const List<_Zone> _zones = [

    // ── Asia ────────────────────────────────────────────────────────────────

    // Bangladesh
    _Zone(20.5, 26.7, 88.0, 92.7, 'Asia/Dhaka'),

    // India – subdivided
    _Zone(8.0, 37.0, 68.0, 97.5, 'Asia/Kolkata'),

    // Pakistan
    _Zone(23.5, 37.1, 60.8, 77.0, 'Asia/Karachi'),

    // Sri Lanka
    _Zone(5.9, 9.9, 79.6, 81.9, 'Asia/Colombo'),

    // Nepal
    _Zone(26.3, 30.5, 80.0, 88.2, 'Asia/Kathmandu'),

    // Bhutan
    _Zone(26.7, 28.4, 88.7, 92.1, 'Asia/Thimphu'),

    // Maldives
    _Zone(-1.0, 7.1, 72.6, 73.7, 'Indian/Maldives'),

    // Myanmar
    _Zone(9.5, 28.6, 92.1, 101.2, 'Asia/Rangoon'),

    // Thailand
    _Zone(5.5, 20.5, 97.3, 105.7, 'Asia/Bangkok'),

    // Vietnam
    _Zone(8.4, 23.4, 102.1, 109.5, 'Asia/Ho_Chi_Minh'),

    // Cambodia
    _Zone(10.4, 14.7, 102.3, 107.6, 'Asia/Phnom_Penh'),

    // Laos
    _Zone(13.9, 22.5, 100.1, 107.7, 'Asia/Vientiane'),

    // Malaysia – Peninsular
    _Zone(1.2, 7.4, 99.6, 104.6, 'Asia/Kuala_Lumpur'),

// Zone table – Peninsular Malaysia
    _Zone(1.2, 7.4, 99.6, 104.6, 'Asia/Kuching'), // ✅ was 'Asia/Kuala_Lumpur'

    // Indonesia – Java/Sumatra (WIB)
    _Zone(-8.8, 5.9, 95.0, 108.8, 'Asia/Jakarta'),

    // Singapore
    _Zone(1.1, 1.5, 103.6, 104.0, 'Asia/Singapore'),


    // Philippines
    _Zone(4.5, 21.2, 116.9, 126.6, 'Asia/Manila'),

    // Indonesia – Bali/NTT (WITA)
    _Zone(-11.0, -7.9, 108.8, 115.7, 'Asia/Makassar'),
    // Indonesia – Maluku/Papua (WIT)
    _Zone(-8.8, 2.0, 130.0, 141.0, 'Asia/Jayapura'),


    // China
    _Zone(18.0, 53.6, 73.5, 135.1, 'Asia/Shanghai'),

    // Taiwan
    _Zone(21.9, 25.3, 119.9, 122.1, 'Asia/Taipei'),

    // Hong Kong
    _Zone(22.1, 22.6, 113.8, 114.5, 'Asia/Hong_Kong'),

    // Macau
    _Zone(22.0, 22.3, 113.5, 113.7, 'Asia/Macau'),

    // Japan
    _Zone(24.0, 45.6, 122.9, 145.8, 'Asia/Tokyo'),

    // South Korea
    _Zone(33.1, 38.6, 125.9, 129.6, 'Asia/Seoul'),

    // North Korea
    _Zone(37.6, 42.9, 124.2, 130.7, 'Asia/Pyongyang'),

    // Mongolia
    _Zone(41.6, 52.2, 87.7, 120.0, 'Asia/Ulaanbaatar'),

    // Afghanistan
    _Zone(29.4, 38.5, 60.5, 74.9, 'Asia/Kabul'),

    // Iran
    _Zone(25.0, 39.8, 44.0, 63.3, 'Asia/Tehran'),

    // Iraq
    _Zone(29.1, 37.4, 38.8, 48.6, 'Asia/Baghdad'),

    // Kuwait
    _Zone(28.5, 30.1, 46.5, 48.4, 'Asia/Kuwait'),

    // Saudi Arabia
    _Zone(16.3, 32.2, 36.4, 55.7, 'Asia/Riyadh'),

    // UAE
    _Zone(22.6, 26.1, 51.6, 56.4, 'Asia/Dubai'),

    // Qatar
    _Zone(24.5, 26.2, 50.7, 51.7, 'Asia/Qatar'),

    // Bahrain
    _Zone(25.8, 26.4, 50.4, 50.7, 'Asia/Bahrain'),

    // Oman
    _Zone(16.6, 26.4, 51.9, 59.9, 'Asia/Muscat'),

    // Yemen
    _Zone(12.1, 19.0, 42.5, 53.2, 'Asia/Aden'),

    // Jordan
    _Zone(29.2, 33.4, 35.5, 39.3, 'Asia/Amman'),

    // Syria
    _Zone(32.3, 37.3, 35.7, 42.4, 'Asia/Damascus'),

    // Lebanon
    _Zone(33.0, 34.7, 35.1, 36.6, 'Asia/Beirut'),

    // Israel / Palestine
    _Zone(29.4, 33.4, 34.2, 35.9, 'Asia/Jerusalem'),

    // Turkey
    _Zone(35.8, 42.1, 26.0, 44.8, 'Europe/Istanbul'),

    // Armenia
    _Zone(38.8, 41.3, 43.4, 46.6, 'Asia/Yerevan'),

    // Azerbaijan
    _Zone(38.4, 41.9, 44.8, 50.4, 'Asia/Baku'),

    // Georgia (country)
    _Zone(41.0, 43.6, 40.0, 46.7, 'Asia/Tbilisi'),

    // Kazakhstan – West
    _Zone(40.6, 55.4, 50.3, 61.3, 'Asia/Aqtau'),
    // Kazakhstan – East
    _Zone(40.6, 55.4, 61.3, 87.4, 'Asia/Almaty'),

    // Uzbekistan
    _Zone(37.1, 45.6, 55.9, 73.1, 'Asia/Tashkent'),

    // Turkmenistan
    _Zone(35.1, 42.8, 52.4, 66.7, 'Asia/Ashgabat'),

    // Tajikistan
    _Zone(36.7, 41.0, 67.4, 75.2, 'Asia/Dushanbe'),

    // Kyrgyzstan
    _Zone(39.2, 43.2, 69.2, 80.3, 'Asia/Bishkek'),

    // Russia – Moscow region
    _Zone(50.0, 70.0, 27.3, 49.0, 'Europe/Moscow'),
    // Russia – Yekaterinburg
    _Zone(50.0, 70.0, 49.0, 67.0, 'Asia/Yekaterinburg'),
    // Russia – Omsk
    _Zone(50.0, 70.0, 67.0, 79.0, 'Asia/Omsk'),
    // Russia – Krasnoyarsk
    _Zone(50.0, 75.0, 79.0, 100.0, 'Asia/Krasnoyarsk'),
    // Russia – Irkutsk
    _Zone(50.0, 75.0, 100.0, 116.0, 'Asia/Irkutsk'),
    // Russia – Yakutsk
    _Zone(50.0, 75.0, 116.0, 135.0, 'Asia/Yakutsk'),
    // Russia – Vladivostok
    _Zone(42.0, 55.0, 130.0, 141.0, 'Asia/Vladivostok'),
    // Russia – Magadan
    _Zone(55.0, 75.0, 141.0, 156.0, 'Asia/Magadan'),
    // Russia – Kamchatka
    _Zone(50.0, 65.0, 156.0, 163.0, 'Asia/Kamchatka'),

    // ── Europe ──────────────────────────────────────────────────────────────

    // UK & Ireland
    _Zone(49.9, 60.9, -8.2, 1.8, 'Europe/London'),
    _Zone(51.4, 55.4, -10.5, -6.0, 'Europe/Dublin'),

    // Portugal (mainland)
    _Zone(36.9, 42.2, -9.5, -6.2, 'Europe/Lisbon'),
    // Azores
    _Zone(36.9, 40.0, -31.3, -25.0, 'Atlantic/Azores'),

    // Spain
    _Zone(35.9, 43.8, -9.3, 4.3, 'Europe/Madrid'),

    // France
    _Zone(41.3, 51.1, -5.1, 9.6, 'Europe/Paris'),

    // Germany
    _Zone(47.3, 55.1, 6.0, 15.1, 'Europe/Berlin'),

    // Italy
    _Zone(35.5, 47.1, 6.6, 18.5, 'Europe/Rome'),

    // Switzerland
    _Zone(45.8, 47.8, 5.9, 10.5, 'Europe/Zurich'),

    // Austria
    _Zone(46.4, 49.0, 9.5, 17.2, 'Europe/Vienna'),

    // Netherlands
    _Zone(50.7, 53.6, 3.3, 7.2, 'Europe/Amsterdam'),

    // Belgium
    _Zone(49.5, 51.5, 2.5, 6.4, 'Europe/Brussels'),

    // Luxembourg
    _Zone(49.4, 50.2, 5.7, 6.5, 'Europe/Luxembourg'),

    // Denmark
    _Zone(54.5, 58.0, 8.0, 15.3, 'Europe/Copenhagen'),

    // Sweden
    _Zone(55.3, 69.1, 11.1, 24.2, 'Europe/Stockholm'),

    // Norway
    _Zone(57.9, 71.2, 4.6, 31.1, 'Europe/Oslo'),

    // Finland
    _Zone(59.7, 70.1, 20.0, 31.6, 'Europe/Helsinki'),

    // Poland
    _Zone(49.0, 54.9, 14.1, 24.2, 'Europe/Warsaw'),

    // Czech Republic
    _Zone(48.5, 51.1, 12.1, 18.9, 'Europe/Prague'),

    // Slovakia
    _Zone(47.7, 49.6, 16.8, 22.6, 'Europe/Bratislava'),

    // Hungary
    _Zone(45.7, 48.6, 16.1, 22.9, 'Europe/Budapest'),

    // Romania
    _Zone(43.6, 48.3, 20.2, 29.7, 'Europe/Bucharest'),

    // Bulgaria
    _Zone(41.2, 44.2, 22.4, 28.6, 'Europe/Sofia'),

    // Greece
    _Zone(34.8, 41.8, 19.4, 29.7, 'Europe/Athens'),

    // Croatia
    _Zone(42.4, 46.6, 13.5, 19.5, 'Europe/Zagreb'),

    // Bosnia & Herzegovina
    _Zone(42.5, 45.3, 15.7, 19.7, 'Europe/Sarajevo'),

    // Serbia
    _Zone(42.2, 46.2, 18.8, 23.0, 'Europe/Belgrade'),

    // Slovenia
    _Zone(45.4, 46.9, 13.4, 16.6, 'Europe/Ljubljana'),

    // Montenegro
    _Zone(41.8, 43.6, 18.4, 20.4, 'Europe/Podgorica'),

    // North Macedonia
    _Zone(40.8, 42.4, 20.4, 23.1, 'Europe/Skopje'),

    // Albania
    _Zone(39.6, 42.7, 19.3, 21.1, 'Europe/Tirane'),

    // Ukraine
    _Zone(44.4, 52.4, 22.1, 40.2, 'Europe/Kiev'),

    // Moldova
    _Zone(45.5, 48.5, 26.6, 30.2, 'Europe/Chisinau'),

    // Belarus
    _Zone(51.3, 56.2, 23.2, 32.8, 'Europe/Minsk'),

    // Lithuania
    _Zone(53.9, 56.5, 20.9, 26.8, 'Europe/Vilnius'),

    // Latvia
    _Zone(55.7, 58.1, 20.9, 28.3, 'Europe/Riga'),

    // Estonia
    _Zone(57.5, 59.7, 21.8, 28.2, 'Europe/Tallinn'),

    // Iceland
    _Zone(63.3, 66.6, -24.5, -13.5, 'Atlantic/Reykjavik'),

    // Malta
    _Zone(35.8, 36.1, 14.2, 14.6, 'Europe/Malta'),

    // Cyprus
    _Zone(34.6, 35.7, 32.3, 34.6, 'Asia/Nicosia'),

    // ── Africa ──────────────────────────────────────────────────────────────

    // Morocco
    _Zone(27.6, 35.9, -13.2, -0.9, 'Africa/Casablanca'),

    // Algeria
    _Zone(18.9, 37.1, -8.7, 12.0, 'Africa/Algiers'),

    // Tunisia
    _Zone(30.2, 37.5, 7.5, 11.6, 'Africa/Tunis'),

    // Libya
    _Zone(19.5, 33.2, 9.3, 25.2, 'Africa/Tripoli'),

    // Egypt
    _Zone(22.0, 31.7, 24.7, 37.1, 'Africa/Cairo'),

    // Sudan
    _Zone(8.7, 22.2, 21.8, 38.6, 'Africa/Khartoum'),

    // South Sudan
    _Zone(3.5, 12.2, 24.0, 35.9, 'Africa/Juba'),

    // Ethiopia
    _Zone(3.4, 15.0, 33.0, 48.0, 'Africa/Addis_Ababa'),

    // Somalia
    _Zone(-1.7, 12.0, 40.9, 51.5, 'Africa/Mogadishu'),

    // Eritrea
    _Zone(12.4, 18.0, 36.4, 43.2, 'Africa/Asmara'),

    // Djibouti
    _Zone(10.9, 12.7, 41.7, 43.4, 'Africa/Djibouti'),

    // Kenya
    _Zone(-4.7, 4.6, 34.0, 41.9, 'Africa/Nairobi'),

    // Uganda
    _Zone(-1.5, 4.2, 29.6, 35.0, 'Africa/Kampala'),

    // Tanzania
    _Zone(-11.8, -1.0, 29.3, 40.6, 'Africa/Dar_es_Salaam'),

    // Rwanda
    _Zone(-2.9, -1.1, 28.8, 30.9, 'Africa/Kigali'),

    // Burundi
    _Zone(-4.5, -2.3, 29.0, 30.9, 'Africa/Bujumbura'),

    // Mozambique
    _Zone(-26.9, -10.5, 32.3, 40.9, 'Africa/Maputo'),

    // Zambia
    _Zone(-18.1, -8.2, 22.0, 33.7, 'Africa/Lusaka'),

    // Zimbabwe
    _Zone(-22.5, -15.6, 25.2, 33.1, 'Africa/Harare'),

    // Malawi
    _Zone(-17.2, -9.4, 32.7, 35.9, 'Africa/Blantyre'),

    // Madagascar
    _Zone(-25.6, -12.0, 43.2, 50.5, 'Indian/Antananarivo'),

    // South Africa
    _Zone(-34.9, -22.1, 16.5, 32.9, 'Africa/Johannesburg'),

    // Namibia
    _Zone(-28.9, -17.0, 11.7, 25.3, 'Africa/Windhoek'),

    // Botswana
    _Zone(-26.9, -17.8, 19.9, 29.4, 'Africa/Gaborone'),

    // Lesotho
    _Zone(-30.7, -28.6, 27.0, 29.5, 'Africa/Maseru'),

    // Eswatini
    _Zone(-27.3, -25.7, 30.8, 32.1, 'Africa/Mbabane'),

    // Angola
    _Zone(-18.1, -4.4, 11.7, 24.1, 'Africa/Luanda'),

    // DR Congo (Kinshasa – west, UTC+1)
    _Zone(-5.0, 5.4, 12.2, 22.0, 'Africa/Kinshasa'),
    // DR Congo (Lubumbashi – east, UTC+2)
    _Zone(-13.5, -5.0, 22.0, 31.3, 'Africa/Lubumbashi'),

    // Republic of Congo
    _Zone(-5.1, 3.7, 11.1, 18.7, 'Africa/Brazzaville'),

    // Cameroon
    _Zone(1.7, 13.1, 8.5, 16.2, 'Africa/Douala'),

    // Nigeria
    _Zone(4.3, 13.9, 2.7, 14.7, 'Africa/Lagos'),

    // Ghana
    _Zone(4.7, 11.2, -3.3, 1.2, 'Africa/Accra'),

    // Ivory Coast
    _Zone(4.3, 10.7, -8.6, -2.5, 'Africa/Abidjan'),

    // Senegal
    _Zone(12.3, 16.7, -17.5, -11.4, 'Africa/Dakar'),

    // Mali
    _Zone(10.1, 25.0, -4.2, 4.3, 'Africa/Bamako'),

    // Burkina Faso
    _Zone(9.4, 15.1, -5.5, 2.4, 'Africa/Ouagadougou'),

    // Niger
    _Zone(11.7, 23.5, 0.2, 15.9, 'Africa/Niamey'),

    // Chad
    _Zone(7.4, 23.5, 13.5, 24.0, 'Africa/Ndjamena'),

    // Mauritania
    _Zone(14.7, 27.3, -17.1, -4.8, 'Africa/Nouakchott'),

    // Guinea
    _Zone(7.2, 12.7, -15.1, -7.6, 'Africa/Conakry'),

    // Sierra Leone
    _Zone(6.9, 10.0, -13.4, -10.3, 'Africa/Freetown'),

    // Liberia
    _Zone(4.3, 8.6, -11.5, -7.4, 'Africa/Monrovia'),

    // Togo
    _Zone(6.1, 11.1, -0.1, 1.8, 'Africa/Lome'),

    // Benin
    _Zone(6.2, 12.4, 0.8, 3.9, 'Africa/Porto-Novo'),

    // Gabon
    _Zone(-3.9, 2.3, 8.7, 14.5, 'Africa/Libreville'),

    // Equatorial Guinea
    _Zone(1.0, 3.8, 5.6, 11.4, 'Africa/Malabo'),

    // Central African Republic
    _Zone(2.2, 11.0, 14.4, 27.5, 'Africa/Bangui'),

    // Guinea-Bissau
    _Zone(10.9, 12.7, -16.7, -13.6, 'Africa/Bissau'),

    // Gambia
    _Zone(13.1, 13.8, -17.0, -13.8, 'Africa/Banjul'),

    // Cabo Verde
    _Zone(14.8, 17.2, -25.4, -22.7, 'Atlantic/Cape_Verde'),

    // Comoros
    _Zone(-12.4, -11.4, 43.2, 44.5, 'Indian/Comoro'),

    // Seychelles
    _Zone(-10.2, -3.8, 46.2, 56.3, 'Indian/Mahe'),

    // Mauritius
    _Zone(-20.6, -19.9, 57.3, 57.8, 'Indian/Mauritius'),

    // Reunion
    _Zone(-21.4, -20.9, 55.2, 55.8, 'Indian/Reunion'),

    // ── Americas ─────────────────────────────────────────────────────────────

    // Canada – Pacific
    _Zone(48.3, 60.0, -139.1, -114.1, 'America/Vancouver'),
    // Canada – Mountain
    _Zone(48.9, 60.0, -114.1, -101.3, 'America/Edmonton'),
    // Canada – Central
    _Zone(48.9, 60.0, -101.3, -88.9, 'America/Winnipeg'),
    // Canada – Eastern
    _Zone(41.7, 60.0, -88.9, -52.7, 'America/Toronto'),
    // Canada – Atlantic
    _Zone(43.4, 60.0, -66.9, -52.7, 'America/Halifax'),
    // Newfoundland
    _Zone(46.6, 51.7, -59.5, -52.6, 'America/St_Johns'),

    // USA – Hawaii
    _Zone(18.9, 28.4, -178.4, -154.8, 'Pacific/Honolulu'),
    // USA – Alaska
    _Zone(54.6, 71.4, -168.0, -141.0, 'America/Anchorage'),
    // USA – Pacific
    _Zone(32.5, 49.0, -124.7, -114.1, 'America/Los_Angeles'),
    // USA – Mountain
    _Zone(31.3, 49.0, -114.1, -102.0, 'America/Denver'),
    // USA – Central
    _Zone(25.8, 49.4, -102.0, -87.5, 'America/Chicago'),
    // USA – Eastern
    _Zone(24.5, 47.5, -87.5, -66.9, 'America/New_York'),

    // Mexico – Pacific
    _Zone(22.9, 32.7, -117.1, -109.4, 'America/Tijuana'),
    // Mexico – Mountain
    _Zone(22.9, 32.0, -109.4, -103.5, 'America/Chihuahua'),
    // Mexico – Central
    _Zone(14.5, 30.0, -103.5, -86.7, 'America/Mexico_City'),

    // Guatemala
    _Zone(13.7, 17.8, -92.2, -88.2, 'America/Guatemala'),

    // Belize
    _Zone(15.9, 18.5, -89.2, -87.5, 'America/Belize'),

    // Honduras
    _Zone(13.0, 16.5, -89.4, -83.2, 'America/Tegucigalpa'),

    // El Salvador
    _Zone(13.1, 14.5, -90.1, -87.7, 'America/El_Salvador'),

    // Nicaragua
    _Zone(10.7, 15.0, -87.7, -83.1, 'America/Managua'),

    // Costa Rica
    _Zone(8.0, 11.2, -85.9, -82.6, 'America/Costa_Rica'),

    // Panama
    _Zone(7.2, 9.7, -83.1, -77.2, 'America/Panama'),

    // Cuba
    _Zone(19.8, 23.3, -84.9, -74.1, 'America/Havana'),

    // Jamaica
    _Zone(17.7, 18.5, -78.4, -76.2, 'America/Jamaica'),

    // Haiti
    _Zone(18.0, 20.1, -74.5, -71.6, 'America/Port-au-Prince'),

    // Dominican Republic
    _Zone(17.5, 20.0, -72.0, -68.3, 'America/Santo_Domingo'),

    // Puerto Rico
    _Zone(17.9, 18.5, -67.3, -65.2, 'America/Puerto_Rico'),

    // Trinidad & Tobago
    _Zone(10.0, 11.4, -61.9, -60.5, 'America/Port_of_Spain'),

    // Colombia
    _Zone(-4.2, 12.5, -79.0, -66.9, 'America/Bogota'),

    // Venezuela
    _Zone(0.6, 12.2, -73.4, -59.8, 'America/Caracas'),

    // Guyana
    _Zone(1.2, 8.6, -61.4, -57.0, 'America/Guyana'),

    // Suriname
    _Zone(1.8, 6.0, -58.1, -53.9, 'America/Paramaribo'),

    // Ecuador
    _Zone(-5.0, 1.5, -81.0, -75.2, 'America/Guayaquil'),

    // Peru
    _Zone(-18.4, -0.0, -81.3, -68.7, 'America/Lima'),

    // Bolivia
    _Zone(-22.9, -9.7, -69.6, -57.5, 'America/La_Paz'),

    // Brazil – Acre (UTC-5)
    _Zone(-11.2, -7.1, -73.9, -66.6, 'America/Rio_Branco'),
    // Brazil – Amazon (UTC-4)
    _Zone(-16.4, 5.3, -73.9, -49.9, 'America/Manaus'),
    // Brazil – East/Brasilia (UTC-3)
    _Zone(-33.8, 5.3, -49.9, -34.8, 'America/Sao_Paulo'),

    // Chile – mainland
    _Zone(-55.9, -17.5, -75.7, -66.4, 'America/Santiago'),
    // Chile – Easter Island
    _Zone(-27.2, -27.0, -109.5, -109.2, 'Pacific/Easter'),

    // Argentina
    _Zone(-55.1, -21.8, -73.6, -53.6, 'America/Argentina/Buenos_Aires'),

    // Uruguay
    _Zone(-34.0, -30.1, -58.4, -53.1, 'America/Montevideo'),

    // Paraguay
    _Zone(-27.6, -19.3, -62.6, -54.3, 'America/Asuncion'),

    // ── Pacific / Oceania ────────────────────────────────────────────────────

    // Australia – Western (AWST)
    _Zone(-35.2, -13.7, 112.9, 129.0, 'Australia/Perth'),
    // Australia – Central (ACST)
    _Zone(-38.1, -25.9, 129.0, 141.0, 'Australia/Darwin'),
    // Australia – Eastern (AEST)
    _Zone(-43.7, -10.7, 141.0, 153.7, 'Australia/Sydney'),

    // New Zealand
    _Zone(-47.4, -34.4, 166.4, 178.6, 'Pacific/Auckland'),
    // Chatham Islands
    _Zone(-44.1, -43.7, -176.6, -176.1, 'Pacific/Chatham'),

    // Papua New Guinea
    _Zone(-11.7, -1.3, 140.8, 155.9, 'Pacific/Port_Moresby'),

    // Fiji
    _Zone(-20.7, -15.7, 177.1, 180.0, 'Pacific/Fiji'),

    // Solomon Islands
    _Zone(-11.9, -5.0, 155.5, 162.8, 'Pacific/Guadalcanal'),

    // Vanuatu
    _Zone(-20.3, -13.1, 166.5, 170.3, 'Pacific/Efate'),

    // Samoa (independent)
    _Zone(-14.1, -13.4, -172.8, -171.4, 'Pacific/Apia'),

    // Tonga
    _Zone(-21.5, -15.6, -175.4, -173.7, 'Pacific/Tongatapu'),

    // Kiribati – Line Islands
    _Zone(-11.6, 2.0, -157.5, -150.2, 'Pacific/Kiritimati'),

    // Guam
    _Zone(13.2, 13.7, 144.6, 145.0, 'Pacific/Guam'),

    // Hawaii (USA)
    _Zone(18.9, 28.4, -178.4, -154.8, 'Pacific/Honolulu'),

    // ── Atlantic islands ─────────────────────────────────────────────────────

    // Greenland
    _Zone(59.8, 83.7, -73.0, -12.0, 'America/Godthab'),

    // Canary Islands (Spain)
    _Zone(27.6, 29.5, -18.2, -13.4, 'Atlantic/Canary'),

    // Madeira (Portugal)
    _Zone(32.6, 33.2, -17.3, -16.3, 'Atlantic/Madeira'),

    // Faroe Islands
    _Zone(61.4, 62.4, -7.7, -6.3, 'Atlantic/Faroe'),

    // Bermuda
    _Zone(32.2, 32.4, -64.9, -64.6, 'Atlantic/Bermuda'),

    // Falkland Islands
    _Zone(-53.0, -51.0, -61.4, -57.7, 'Atlantic/Stanley'),
  ];
}