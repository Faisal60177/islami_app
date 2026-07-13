import 'package:timezone/timezone.dart' as tz;
import 'package:muslim_app/home/model/prayer_times_models.dart';
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

  /// Re-runs the full schedule using today's prayer times. Called every
  /// time PrayerTimesCubit emits PrayerTimesLoaded (new day or new location),
  /// so tomorrow's alarms never fire using today's stale times.
  Future<void> rescheduleAll({
    required PrayerTimesModel prayerTimes,
    required Map<String, PrayerAlarmSetting> settings,
  }) async {
    await _notif.cancelAllPrayerNotifications();

    final now = DateTime.now();
    final weekday = now.weekday;

    for (final prayerId in allSchedulablePrayerIds) {
      final setting = settings[prayerId];
      if (setting == null) continue;

      final baseTime = _prayerTimeFor(prayerTimes, prayerId);
      if (baseTime == null) continue;

      if (!setting.isActiveOn(weekday)) continue;

      final alarmTime = baseTime.add(Duration(minutes: setting.offsetMinutes));
      if (setting.enabled && alarmTime.isAfter(now)) {
        await _notif.scheduleAlarm(
          id: alarmNotificationId(prayerId),
          title: '${_labelFor(prayerId)} prayer',
          body: setting.offsetMinutes == 0
              ? '${_labelFor(prayerId)} time has arrived'
              : '${_labelFor(prayerId)} in ${setting.offsetMinutes.abs()} min',
          scheduledDate: _toTz(alarmTime),
          // FIX: NotificationService.scheduleAlarm now takes the full
          // AlarmSoundType (silent/beep/adhan), not a single useAdhanSound
          // bool — passing setting.soundType directly lets it correctly
          // branch to the silent-notification path or the ring-service path.
          soundType: setting.soundType,
          vibrate: setting.vibrationEnabled,
        );
      }

      if (setting.waqtStartNotificationEnabled && baseTime.isAfter(now)) {
        await _notif.scheduleWaqtPing(
          id: waqtNotificationId(prayerId),
          title: '${_labelFor(prayerId)} waqt started',
          body: '${_labelFor(prayerId)} time has begun',
          scheduledDate: _toTz(baseTime),
        );
      }
    }
  }
}