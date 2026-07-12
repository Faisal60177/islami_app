import 'package:equatable/equatable.dart';
import '../model/alarm_settings_model.dart';

class AlarmState extends Equatable {
  final Map<String, PrayerAlarmSetting> settings;
  final bool isLoading;

  const AlarmState({this.settings = const {}, this.isLoading = true});

  AlarmState copyWith({
    Map<String, PrayerAlarmSetting>? settings,
    bool? isLoading,
  }) {
    return AlarmState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading];
}