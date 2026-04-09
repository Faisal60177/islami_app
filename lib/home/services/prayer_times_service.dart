import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../location/model/location_model.dart';
import '../model/prayer_times_models.dart';

class PrayerTimesService {

  // ── shared builder ────────────────────────────────────────────────────────

  static PrayerTimesModel _buildModel(PrayerTimes prayerTimes, tz.Location timezone) {
    return PrayerTimesModel(
      fajrStart:     tz.TZDateTime.from(prayerTimes.fajr,    timezone),
      fajrEnd:       tz.TZDateTime.from(prayerTimes.sunrise, timezone).subtract(const Duration(minutes: 1)),

      sunRiseStart:  tz.TZDateTime.from(prayerTimes.sunrise, timezone),
      sunRiseEnd:    tz.TZDateTime.from(prayerTimes.sunrise, timezone).add(const Duration(minutes: 15)),

      noonStart:     tz.TZDateTime.from(prayerTimes.dhuhr,   timezone).subtract(const Duration(minutes: 6)),
      noonEnd:       tz.TZDateTime.from(prayerTimes.dhuhr,   timezone).subtract(const Duration(minutes: 1)),

      sunSetStart:   tz.TZDateTime.from(prayerTimes.maghrib, timezone).subtract(const Duration(minutes: 15)),
      sunSetEnd:     tz.TZDateTime.from(prayerTimes.maghrib, timezone).subtract(const Duration(minutes: 1)),

      dhuhrStart:    tz.TZDateTime.from(prayerTimes.dhuhr,   timezone),
      dhuhrEnd:      tz.TZDateTime.from(prayerTimes.asr,     timezone).subtract(const Duration(minutes: 1)),

      asrStart:      tz.TZDateTime.from(prayerTimes.asr,     timezone),
      asrEnd:        tz.TZDateTime.from(prayerTimes.maghrib, timezone).subtract(const Duration(minutes: 1)),

      maghribStart:  tz.TZDateTime.from(prayerTimes.maghrib, timezone),
      maghribEnd:    tz.TZDateTime.from(prayerTimes.isha,    timezone).subtract(const Duration(minutes: 1)),

      ishaStart:     tz.TZDateTime.from(prayerTimes.isha,    timezone),
      ishaEnd:       tz.TZDateTime.from(prayerTimes.fajr,    timezone).subtract(const Duration(minutes: 1)),

      ishraqStart:   tz.TZDateTime.from(prayerTimes.sunrise, timezone).add(const Duration(minutes: 16)),
      ishraqEnd:     tz.TZDateTime.from(prayerTimes.dhuhr,   timezone).subtract(const Duration(minutes: 7)),

      chashtStart:   tz.TZDateTime.from(prayerTimes.sunrise, timezone).add(const Duration(minutes: 16)),
      chashtEnd:     tz.TZDateTime.from(prayerTimes.dhuhr,   timezone).subtract(const Duration(minutes: 7)),

      tahajjudStart: tz.TZDateTime.from(prayerTimes.isha,    timezone),
      tahajjudEnd:   tz.TZDateTime.from(prayerTimes.fajr,    timezone).subtract(const Duration(minutes: 1)),

      awabinStart:   tz.TZDateTime.from(prayerTimes.maghrib, timezone),
      awabinEnd:     tz.TZDateTime.from(prayerTimes.isha,    timezone).subtract(const Duration(minutes: 1)),

      zawalStart:    tz.TZDateTime.from(prayerTimes.dhuhr,   timezone),

      sahriEnd:      tz.TZDateTime.from(prayerTimes.fajr,    timezone).subtract(const Duration(minutes: 1)),
      iftarTime:     tz.TZDateTime.from(prayerTimes.maghrib, timezone),
    );
  }

  // ── for today (used by cubit on location load) ────────────────────────────

  static Future<PrayerTimesModel> getPrayerTimesForLocation(
      LocationModel location, String timeZoneName) async {
    return getPrayerTimesForDate(location, timeZoneName, DateTime.now());
  }

  // ── for any date (used by calendar page) ─────────────────────────────────

  static Future<PrayerTimesModel> getPrayerTimesForDate(
      LocationModel location, String timeZoneName, DateTime date) async {
    final coordinates = Coordinates(location.latitude, location.longitude);

    final params = CalculationMethodParameters.karachi()
      ..madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,                  // ✅ uses the passed date
      calculationParameters: params,
      precision: true,
    );

    final timezone = tz.getLocation(timeZoneName);

    return _buildModel(prayerTimes, timezone);
  }
}