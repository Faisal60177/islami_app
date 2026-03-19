import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/prayer_times_models.dart';

class PrayerTimesStorage {
  static const String _key = 'prayerTimes';

  Future<void> savePrayerTimes(PrayerTimesModel times) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(times.toJson()));
  }

  Future<PrayerTimesModel?> getSavedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      return PrayerTimesModel.fromJson(jsonDecode(data));
    }
    return null;
  }
}