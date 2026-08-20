import 'package:shared_preferences/shared_preferences.dart';
import '../model/alarm_settings_model.dart';

class AlarmRepository {
  static const _prefix = 'alarm_setting_';

  Future<Map<String, PrayerAlarmSetting>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, PrayerAlarmSetting> result = {};
    for (final id in [...farzPrayerIds, ...nafalPrayerIds]) {
      final raw = prefs.getString('$_prefix$id');
      result[id] = raw != null
          ? PrayerAlarmSetting.decode(id, raw)
          : PrayerAlarmSetting.defaultFor(id);
    }
    return result;
  }

  Future<void> save(PrayerAlarmSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${setting.prayerId}', setting.encode());
  }
}