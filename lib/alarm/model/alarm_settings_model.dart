import 'dart:convert';

enum AlarmSoundType { silent, systemDefault, adhan }
enum RepeatMode { everyday, customDays }

class PrayerAlarmSetting {
  final String prayerId;
  final bool enabled;
  final int offsetMinutes;
  final AlarmSoundType soundType;
  final bool vibrationEnabled;
  final RepeatMode repeatMode;
  final Set<int> customWeekdays; // 1=Mon .. 7=Sun, used when repeatMode == customDays
  final bool waqtStartNotificationEnabled; // passive "prayer started" ping

  const PrayerAlarmSetting({
    required this.prayerId,
    this.enabled = true,
    this.offsetMinutes = 0,
    this.soundType = AlarmSoundType.adhan,
    this.vibrationEnabled = true,
    this.repeatMode = RepeatMode.everyday,
    this.customWeekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.waqtStartNotificationEnabled = true,
  });

  PrayerAlarmSetting copyWith({
    bool? enabled,
    int? offsetMinutes,
    AlarmSoundType? soundType,
    bool? vibrationEnabled,
    RepeatMode? repeatMode,
    Set<int>? customWeekdays,
    bool? waqtStartNotificationEnabled,
  }) {
    return PrayerAlarmSetting(
      prayerId: prayerId,
      enabled: enabled ?? this.enabled,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      soundType: soundType ?? this.soundType,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      customWeekdays: customWeekdays ?? this.customWeekdays,
      waqtStartNotificationEnabled:
      waqtStartNotificationEnabled ?? this.waqtStartNotificationEnabled,
    );
  }

  bool isActiveOn(int weekday) {
    if (repeatMode == RepeatMode.everyday) return true;
    return customWeekdays.contains(weekday);
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'offsetMinutes': offsetMinutes,
    'soundType': soundType.index,
    'vibrationEnabled': vibrationEnabled,
    'repeatMode': repeatMode.index,
    'customWeekdays': customWeekdays.toList(),
    'waqtStartNotificationEnabled': waqtStartNotificationEnabled,
  };

  factory PrayerAlarmSetting.fromMap(String prayerId, Map<String, dynamic> map) {
    return PrayerAlarmSetting(
      prayerId: prayerId,
      enabled: map['enabled'] as bool? ?? true,
      offsetMinutes: map['offsetMinutes'] as int? ?? 0,
      soundType: AlarmSoundType.values[
      (map['soundType'] as int?) ?? AlarmSoundType.adhan.index],
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
      repeatMode: RepeatMode.values[
      (map['repeatMode'] as int?) ?? RepeatMode.everyday.index],
      customWeekdays: map['customWeekdays'] != null
          ? Set<int>.from((map['customWeekdays'] as List).map((e) => e as int))
          : {1, 2, 3, 4, 5, 6, 7},
      waqtStartNotificationEnabled:
      map['waqtStartNotificationEnabled'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toMap());

  factory PrayerAlarmSetting.decode(String prayerId, String raw) {
    return PrayerAlarmSetting.fromMap(
        prayerId, jsonDecode(raw) as Map<String, dynamic>);
  }
}

// ── Prayer groupings ─────────────────────────────────────────────────────────
const List<String> farzPrayerIds  = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const List<String> nafalPrayerIds = ['chasht', 'tahajjud'];

// ── Notification ID scheme (used by the scheduler) ──────────────────────────
// Alarm ids: 100-106, Waqt-ping ids: 200-206, mapped by index in this order.
const List<String> allSchedulablePrayerIds = [
  'fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'chasht', 'tahajjud',
];

int alarmNotificationId(String prayerId) =>
    100 + allSchedulablePrayerIds.indexOf(prayerId);

int waqtNotificationId(String prayerId) =>
    200 + allSchedulablePrayerIds.indexOf(prayerId);