import 'package:muslim_app/home/widgets/mosque.dart';
import 'package:muslim_app/home/home_page.dart';
import '../model/prayer_times_models.dart';

abstract class PrayerTimesState {}

class PrayerTimesInitial extends PrayerTimesState {}
class PrayerTimesLoading extends PrayerTimesState {}
class PrayerTimesLoaded extends PrayerTimesState {
  final PrayerTimesModel prayerTimes;
  PrayerTimesLoaded(this.prayerTimes);
}
class PrayerTimesError extends PrayerTimesState {
  final String message;
  PrayerTimesError(this.message);
}