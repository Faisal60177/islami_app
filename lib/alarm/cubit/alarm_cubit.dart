import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/location/model/location_model.dart';
import 'package:muslim_app/location/services/location_storage.dart';
import '../model/alarm_settings_model.dart';
import '../repository/alarm_repository.dart';
import '../services/prayer_notification_scheduler.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  final AlarmRepository _repo;
  final PrayerNotificationScheduler _scheduler;
  final LocationStorage _locationStorage;
  LocationModel? _latestLocation;
  String? _latestTimeZone;

  bool _isRescheduling = false;
  bool _rescheduleQueued = false;

  AlarmCubit({
    AlarmRepository? repository,
    PrayerNotificationScheduler? scheduler,
    LocationStorage? locationStorage,
  })  : _repo = repository ?? AlarmRepository(),
        _scheduler = scheduler ?? PrayerNotificationScheduler(),
        _locationStorage = locationStorage ?? LocationStorage(),
        super(const AlarmState());
  Future<void> load() async {
    final settings = await _repo.loadAll();
    emit(state.copyWith(settings: settings, isLoading: false));

    final savedLocation = await _locationStorage.getSavedLocation();
    if (savedLocation != null) {
      _latestLocation = savedLocation;
      _latestTimeZone = savedLocation.timeZone;
    }
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

  Future<void> onLocationUpdated({
    required LocationModel location,
    required String timeZoneName,
  }) async {
    _latestLocation = location;
    _latestTimeZone = timeZoneName;
    await _rescheduleIfPossible();
  }

  Future<void> _rescheduleIfPossible() async {
    final location = _latestLocation;
    final timeZoneName = _latestTimeZone;
    if (location == null || timeZoneName == null) return;

    if (_isRescheduling) {
      _rescheduleQueued = true;
      return;
    }
    _isRescheduling = true;
    try {
      await _scheduler.rescheduleAll(
        location: location,
        timeZoneName: timeZoneName,
        settings: state.settings,
      );
    } finally {
      _isRescheduling = false;
      if (_rescheduleQueued) {
        _rescheduleQueued = false;
        await _rescheduleIfPossible();
      }
    }
  }
}