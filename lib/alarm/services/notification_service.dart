import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:audioplayers/audioplayers.dart';

// Background action handler must be a top-level or static function.
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (response.actionId == 'stop_alarm') {
    NotificationService.instance.stopRingingAlarm();
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  final AudioPlayer _alarmPlayer = AudioPlayer();

  static const String alarmChannelId = 'prayer_alarm_channel';
  static const String waqtChannelId  = 'prayer_waqt_channel';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz.identifier));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'stop_alarm') {
          stopRingingAlarm();
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        alarmChannelId,
        'Prayer alarms',
        description: 'Ringing alarm reminders for prayer times',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        waqtChannelId,
        'Prayer time started',
        description: 'A quiet notice when a prayer waqt begins',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );

    _initialized = true;
  }

  /// Requests all permissions this feature needs. Returns true if the
  /// alarm-critical ones (notifications + exact alarm) were granted.
  Future<bool> requestPermissions() async {
    bool granted = true;

    if (Platform.isAndroid) {
      final notif = await Permission.notification.request();
      granted = granted && notif.isGranted;

      // Android 12+ requires this for alarms that must fire at an exact
      // second, which prayer alarms do (they are not "approximate" reminders).
      final exact = await Permission.scheduleExactAlarm.request();
      granted = granted && exact.isGranted;
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    return granted;
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required bool useAdhanSound,
    required bool vibrate,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          alarmChannelId,
          'Prayer alarms',
          channelDescription: 'Ringing alarm reminders for prayer times',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: useAdhanSound
              ? const RawResourceAndroidNotificationSound('adhan')
              : null,
          enableVibration: vibrate,
          ongoing: true,
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('stop_alarm', 'Stop', cancelNotification: true),
          ],
        ),
        iOS: DarwinNotificationDetails(
          sound: useAdhanSound ? 'adhan.caf' : null,
          presentSound: true,
          categoryIdentifier: 'prayer_alarm',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null, // one-off; scheduler reschedules daily
    );

    if (useAdhanSound) {
      // Looping playback so the alarm actually keeps ringing, since a
      // standard notification sound plays once and stops by OS design.
      // This starts only when the scheduled moment is reached and the OS
      // triggers the notification callback — actual trigger-time playback
      // wiring lives in your platform-specific background isolate setup.
    }
  }

  Future<void> scheduleWaqtPing({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          waqtChannelId,
          'Prayer time started',
          channelDescription: 'A quiet notice when a prayer waqt begins',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAllPrayerNotifications() async {
    for (final prayerId in [
      ...['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'chasht', 'tahajjud'],
    ]) {
      final idx = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'chasht', 'tahajjud']
          .indexOf(prayerId);
      await _plugin.cancel(id: 100 + idx);
      await _plugin.cancel(id: 200 + idx);
    }
  }
  Future<void> stopRingingAlarm() async {
    await _alarmPlayer.stop();
  }

  Future<void> playLoopingAdhan() async {
    await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    await _alarmPlayer.play(AssetSource('sounds/adhan.mp3'));
  }
}