import 'package:timezone/timezone.dart' as tz;
import 'package:muslim_app/home/model/prayer_times_models.dart';
import 'package:muslim_app/home/services/prayer_times_service.dart';
import 'package:muslim_app/location/model/location_model.dart';
import '../model/alarm_settings_model.dart';
import 'notification_service.dart';

class PrayerNotificationScheduler {
  final NotificationService _notif = NotificationService.instance;

  DateTime? _prayerTimeFor(PrayerTimesModel t, String prayerId) {
    switch (prayerId) {
      case 'fajr':     return t.fajrStart;
      case 'dhuhr':    return t.dhuhrStart;
      case 'asr':      return t.asrStart;
      case 'maghrib':  return t.maghribStart;
      case 'isha':     return t.ishaStart;
      case 'chasht':   return t.chashtStart;
      case 'tahajjud': return t.tahajjudStart;
      default: return null;
    }
  }

  String _labelFor(String prayerId) {
    switch (prayerId) {
      case 'fajr':     return 'Fajr';
      case 'dhuhr':    return 'Dhuhr';
      case 'asr':      return 'Asr';
      case 'maghrib':  return 'Maghrib';
      case 'isha':     return 'Isha';
      case 'chasht':   return 'Chasht';
      case 'tahajjud': return 'Tahajjud';
      default: return prayerId;
    }
  }

  tz.TZDateTime _toTz(DateTime dt) => tz.TZDateTime.from(dt, tz.local);

  Future<void> rescheduleAll({
    required LocationModel location,
    required String timeZoneName,
    required Map<String, PrayerAlarmSetting> settings,
    int daysAhead = scheduleDaysAhead,
  }) async {
    await _notif.cancelAllPrayerNotifications();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final weekday = date.weekday;

      final PrayerTimesModel prayerTimes;
      try {
        prayerTimes = await PrayerTimesService.getPrayerTimesForDate(
          location, timeZoneName, date,
        );
      } catch (_) {
        continue;
      }

      for (final prayerId in allSchedulablePrayerIds) {
        final setting = settings[prayerId];
        if (setting == null) continue;

        final baseTime = _prayerTimeFor(prayerTimes, prayerId);
        if (baseTime == null) continue;
        if (!setting.isActiveOn(weekday)) continue;

        final alarmTime = baseTime.add(Duration(minutes: setting.offsetMinutes));

        if (setting.enabled && alarmTime.isAfter(now)) {
          await _notif.scheduleAlarm(
            id: alarmNotificationId(prayerId, dayOffset),
            title: '${_labelFor(prayerId)} Prayer',
            body: setting.offsetMinutes == 0
                ? '${_labelFor(prayerId)} Time has arrived'
                : '${_labelFor(prayerId)} in ${setting.offsetMinutes.abs()} min',
            scheduledDate: _toTz(alarmTime),
            soundType: setting.soundType,
            vibrate: setting.vibrationEnabled,
          );
        }

        if (setting.waqtStartNotificationEnabled && baseTime.isAfter(now)) {
          await _notif.scheduleWaqtPing(
            id: waqtNotificationId(prayerId, dayOffset),
            title: '${_labelFor(prayerId)} Waqt started',
            body: '${_labelFor(prayerId)} Time has begun',
            scheduledDate: _toTz(baseTime),
          );
        }
      }
    }
    await _notif.flushScheduledIds();
  }
}