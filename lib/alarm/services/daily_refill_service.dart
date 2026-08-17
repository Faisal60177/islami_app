import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:muslim_app/location/services/location_storage.dart';
import '../repository/alarm_repository.dart';
import '../model/alarm_settings_model.dart';
import 'prayer_notification_scheduler.dart';

const int dailyRefillAlarmId = 999999;

class DailyRefillService {
  static Future<void> ensureChainStarted() async {
    await _runScheduling();
    await _armNextMidnight();
  }

  @pragma('vm:entry-point')
  static Future<void> refillCallback(int id, Map<String, dynamic> params) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _runScheduling();
    await _armNextMidnight();
  }

  static Future<void> _runScheduling() async {
    final locationStorage = LocationStorage();
    final savedLocation = await locationStorage.getSavedLocation();
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
      rescheduleOnReboot: true,
      params: const {},
    );
  }

  static Future<void> cancel() async {
    await AndroidAlarmManager.cancel(dailyRefillAlarmId);
  }
}