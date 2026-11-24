import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:muslim_app/features/location/data/models/location_model.dart';
import 'package:muslim_app/features/prayer_times/data/models/prayer_times_models.dart';

class PrayerTimesService {

  static PrayerTimesModel _buildModel(PrayerTimes prayerTimes, tz.Location timezone) {

    DateTime loc(DateTime tzDt) {
      final t = tz.TZDateTime.from(tzDt, timezone);
      return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
    }
    return PrayerTimesModel(
      fajrStart:     loc(prayerTimes.fajr),
      fajrEnd:       loc(prayerTimes.sunrise).subtract(const Duration(minutes: 1)),

      sunRiseStart:  loc(prayerTimes.sunrise),
      sunRiseEnd:    loc(prayerTimes.sunrise).add(const Duration(minutes: 15)),

      noonStart:     loc(prayerTimes.dhuhr).subtract(const Duration(minutes: 6)),
      noonEnd:       loc(prayerTimes.dhuhr).subtract(const Duration(minutes: 1)),

      sunSetStart:   loc(prayerTimes.maghrib).subtract(const Duration(minutes: 15)),
      sunSetEnd:     loc(prayerTimes.maghrib).subtract(const Duration(minutes: 1)),

      dhuhrStart:    loc(prayerTimes.dhuhr),
      dhuhrEnd:      loc(prayerTimes.asr).subtract(const Duration(minutes: 1)),

      asrStart:      loc(prayerTimes.asr),
      asrEnd:        loc(prayerTimes.maghrib).subtract(const Duration(minutes: 1)),

      maghribStart:  loc(prayerTimes.maghrib),
      maghribEnd:    loc(prayerTimes.isha).subtract(const Duration(minutes: 1)),

      ishaStart:     loc(prayerTimes.isha),
      ishaEnd:       loc(prayerTimes.fajr).subtract(const Duration(minutes: 1)),

      ishraqStart:   loc(prayerTimes.sunrise).add(const Duration(minutes: 16)),
      ishraqEnd:     loc(prayerTimes.dhuhr).subtract(const Duration(minutes: 7)),

      chashtStart:   loc(prayerTimes.sunrise).add(const Duration(minutes: 16)),
      chashtEnd:     loc(prayerTimes.dhuhr).subtract(const Duration(minutes: 7)),

      tahajjudStart: loc(prayerTimes.isha),
      tahajjudEnd:   loc(prayerTimes.fajr).subtract(const Duration(minutes: 1)),

      awabinStart:   loc(prayerTimes.maghrib),
      awabinEnd:     loc(prayerTimes.isha).subtract(const Duration(minutes: 1)),

      zawalStart:    loc(prayerTimes.dhuhr),

      sahriEnd:      loc(prayerTimes.fajr).subtract(const Duration(minutes: 1)),
      iftarTime:     loc(prayerTimes.maghrib),
    );
  }

  static String _sanitizeTz(String tz) {
    const aliases = {
      'Asia/Kuala_Lumpur': 'Asia/Kuching',
      'Malaysia Time':     'Asia/Kuching',
    };
    return aliases[tz] ?? tz;
  }

  static Future<PrayerTimesModel> getPrayerTimesForLocation(
      LocationModel location, String timeZoneName) async {
    return getPrayerTimesForDate(location, timeZoneName, DateTime.now());
  }

  static Future<PrayerTimesModel> getPrayerTimesForDate(
      LocationModel location, String timeZoneName, DateTime date) async {
    final coordinates = Coordinates(location.latitude, location.longitude);

    final params = CalculationMethodParameters.karachi()
      ..madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
      precision: true,
    );

    final timezone = tz.getLocation(_sanitizeTz(timeZoneName));

    return _buildModel(prayerTimes, timezone);
  }
}