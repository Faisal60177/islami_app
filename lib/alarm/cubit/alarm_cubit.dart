import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/home/model/prayer_times_models.dart';
import '../model/alarm_settings_model.dart';
import '../repository/alarm_repository.dart';
import '../services/prayer_notification_scheduler.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  final AlarmRepository _repo;
  final PrayerNotificationScheduler _scheduler;
  PrayerTimesModel? _latestPrayerTimes;

  AlarmCubit({AlarmRepository? repository, PrayerNotificationScheduler? scheduler})
      : _repo = repository ?? AlarmRepository(),
        _scheduler = scheduler ?? PrayerNotificationScheduler(),
        super(const AlarmState());

  Future<void> load() async {
    final settings = await _repo.loadAll();
    emit(state.copyWith(settings: settings, isLoading: false));
  }

  PrayerAlarmSetting settingFor(String prayerId) =>
      state.settings[prayerId] ?? PrayerAlarmSetting(prayerId: prayerId);

  Future<void> update(PrayerAlarmSetting setting) async {
    final updated = Map<String, PrayerAlarmSetting>.from(state.settings);
    updated[setting.prayerId] = setting;
    emit(state.copyWith(settings: updated));
    await _repo.save(setting);
    await _rescheduleIfPossible();
  }

  /// Called by PrayerTimesCubit's listener whenever prayer times refresh
  /// (new day or new location) — see the wiring note below.
  Future<void> onPrayerTimesUpdated(PrayerTimesModel prayerTimes) async {
    _latestPrayerTimes = prayerTimes;
    await _rescheduleIfPossible();
  }

  Future<void> _rescheduleIfPossible() async {
    final times = _latestPrayerTimes;
    if (times == null) return;
    await _scheduler.rescheduleAll(prayerTimes: times, settings: state.settings);
  }
}