import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:muslim_app/location/services/location_storage.dart';
import '../repository/alarm_repository.dart';
import '../model/alarm_settings_model.dart';
import 'prayer_notification_scheduler.dart';

/// Fixed AlarmManager id for this self-chaining trigger. Kept far outside
/// the 1000-3906 / 5000-7906 ranges used by prayer alarms so it never
/// collides with them.
const int dailyRefillAlarmId = 999999;

class DailyRefillService {
  /// Call once on app startup. Runs the full 30-day scheduling pass right
  /// away (so a fresh install / fresh location doesn't have to wait until
  /// midnight for its first schedule), then arms the midnight trigger
  /// that keeps re-running this forever — independent of the app ever
  /// being reopened.
  static Future<void> ensureChainStarted() async {
    await _runScheduling();
    await _armNextMidnight();
  }

  /// The actual callback AndroidAlarmManager invokes in a background
  /// isolate every midnight. Must be a static method or top-level
  /// function (Android isolate entry-point requirement).
  @pragma('vm:entry-point')
  static Future<void> refillCallback(int id, Map<String, dynamic> params) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _runScheduling();
    await _armNextMidnight(); // re-chain immediately for the next midnight
  }

  static Future<void> _runScheduling() async {
    final locationStorage = LocationStorage();
    final savedLocation = await locationStorage.getSavedLocation();
    // No saved location yet (e.g. very first run before permission is
    // granted) — nothing to schedule this pass; the chain still re-arms
    // itself below and will simply try again next midnight.
    if (savedLocation == null) return;

    final alarmRepo = AlarmRepository();
    final settings = await alarmRepo.loadAll();

    final scheduler = PrayerNotificationScheduler();
    await scheduler.rescheduleAll(
      location: savedLocation,
      timeZoneName: savedLocation.timeZone,
      settings: settings,
      daysAhead: scheduleDaysAhead,
    );
  }

  static Future<void> _armNextMidnight() async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 0, 5); // 12:05 AM
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    await AndroidAlarmManager.oneShotAt(
      next,
      dailyRefillAlarmId,
      refillCallback,
      exact: true,
      wakeup: true,
      // Built-in reboot survival: android_alarm_manager_plus internally
      // registers its own BOOT_COMPLETED handling for any alarm scheduled
      // with rescheduleOnReboot: true — it persists the alarm's params
      // and re-arms them automatically after every reboot, no custom
      // native receiver code needed on our end.
      rescheduleOnReboot: true,
      params: const {},
    );
  }

  static Future<void> cancel() async {
    await AndroidAlarmManager.cancel(dailyRefillAlarmId);
  }
}