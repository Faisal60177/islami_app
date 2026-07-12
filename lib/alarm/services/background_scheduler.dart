import 'package:workmanager/workmanager.dart';
import 'package:muslim_app/location/repository/location_repository.dart';
import 'package:muslim_app/location/services/location_storage.dart';
import 'package:muslim_app/home/services/prayer_times_service.dart';
import '../repository/alarm_repository.dart';
import 'prayer_notification_scheduler.dart';
import 'notification_service.dart';

const String dailyRescheduleTaskName = 'daily_prayer_alarm_reschedule';

@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == dailyRescheduleTaskName) {
      await NotificationService.instance.init();

      final locationStorage = LocationStorage();
      final savedLocation = await locationStorage.getSavedLocation();
      if (savedLocation == null) return Future.value(true);

      final prayerTimes = await PrayerTimesService.getPrayerTimesForLocation(
        savedLocation,
        savedLocation.timeZone,
      );

      final alarmRepo = AlarmRepository();
      final settings = await alarmRepo.loadAll();

      final scheduler = PrayerNotificationScheduler();
      await scheduler.rescheduleAll(prayerTimes: prayerTimes, settings: settings);
    }
    return Future.value(true);
  });
}

class BackgroundScheduler {
  static Future<void> initializeAndSchedule() async {
    await Workmanager().initialize(backgroundTaskDispatcher);
    await Workmanager().registerPeriodicTask(
      dailyRescheduleTaskName,
      dailyRescheduleTaskName,
      frequency: const Duration(hours: 12),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }
}