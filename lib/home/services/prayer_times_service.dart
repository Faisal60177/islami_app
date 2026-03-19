import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../location/model/location_model.dart';
import '../model/prayer_times_models.dart';

class PrayerTimesService {
  /// Calculate prayer times for a given location using Karachi/Hanafi
  static Future<PrayerTimesModel> getPrayerTimesForLocation(
      LocationModel location, String timeZoneName) async {
    final coordinates = Coordinates(location.latitude, location.longitude);

    // Karachi method + Hanafi madhab
    final params = CalculationMethodParameters.karachi()
      ..madhab = Madhab.hanafi;

    final date = DateTime.now();

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
      precision: true,
    );

    final timezone = tz.getLocation(timeZoneName);

    return PrayerTimesModel(
      fajrStart: tz.TZDateTime.from(prayerTimes.fajr, timezone),
      fajrEnd: tz.TZDateTime.from(prayerTimes.sunrise, timezone).subtract(const Duration(minutes: 1)),

      sunRiseStart: tz.TZDateTime.from(prayerTimes.sunrise, timezone),
      sunRiseEnd: tz.TZDateTime.from(prayerTimes.sunrise, timezone).add(const Duration(minutes: 15)),
      noonStart: tz.TZDateTime.from(prayerTimes.dhuhr, timezone).subtract(const Duration(minutes: 6)),
      noonEnd: tz.TZDateTime.from(prayerTimes.dhuhr, timezone).subtract(const Duration(minutes: 1)),
      sunSetStart: tz.TZDateTime.from(prayerTimes.maghrib, timezone).subtract(const Duration(minutes: 15)),
      sunSetEnd: tz.TZDateTime.from(prayerTimes.maghrib, timezone).subtract(const Duration(minutes: 1)),

      dhuhrStart: tz.TZDateTime.from(prayerTimes.dhuhr, timezone),
      dhuhrEnd: tz.TZDateTime.from(prayerTimes.asr, timezone).subtract(const Duration(minutes: 1)),

      asrStart: tz.TZDateTime.from(prayerTimes.asr, timezone),
      asrEnd: tz.TZDateTime.from(prayerTimes.maghrib, timezone).subtract(const Duration(minutes: 1)),

      maghribStart: tz.TZDateTime.from(prayerTimes.maghrib, timezone),
      maghribEnd: tz.TZDateTime.from(prayerTimes.isha, timezone).subtract(const Duration(minutes: 1)),

      ishaStart: tz.TZDateTime.from(prayerTimes.isha, timezone),
      ishaEnd: tz.TZDateTime.from(prayerTimes.fajr, timezone).subtract(const Duration(minutes: 1)),

      ishraqStart: tz.TZDateTime.from(prayerTimes.sunrise, timezone).add(const Duration(minutes: 1)),
      ishraqEnd: tz.TZDateTime.from(prayerTimes.dhuhr, timezone).subtract(const Duration(minutes: 6)),
      chashtStart: tz.TZDateTime.from(prayerTimes.sunrise, timezone).add(const Duration(minutes: 1)),
      chashtEnd: tz.TZDateTime.from(prayerTimes.dhuhr, timezone).subtract(const Duration(minutes: 6)),
      tahajjudStart: tz.TZDateTime.from(prayerTimes.isha, timezone),
      tahajjudEnd: tz.TZDateTime.from(prayerTimes.fajr, timezone).subtract(const Duration(minutes: 1)),
      awabinStart: tz.TZDateTime.from(prayerTimes.maghrib, timezone),
      awabinEnd: tz.TZDateTime.from(prayerTimes.isha, timezone).subtract(const Duration(minutes: 1)),
      zawalStart: tz.TZDateTime.from(prayerTimes.dhuhr, timezone),

      sahriEnd: tz.TZDateTime.from(prayerTimes.fajr, timezone).subtract(const Duration(minutes: 1)),
      iftarTime: tz.TZDateTime.from(prayerTimes.maghrib, timezone),

    );
  }
}