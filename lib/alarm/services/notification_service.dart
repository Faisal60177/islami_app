import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'adhan_alarm_service.dart';

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (response.actionId == 'stop_alarm') {
    NotificationService.instance.stopRingingAlarm(response.id ?? 0);
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  final AudioPlayer _previewPlayer = AudioPlayer();

  static const String alarmChannelId = 'prayer_alarm_channel';
  static const String waqtChannelId  = 'prayer_waqt_channel';
  static const String ringingChannelId = 'prayer_ringing_channel';

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
          stopRingingAlarm(response.id ?? 0);
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
        description: 'Alarm reminders for prayer times (default/silent sound)',
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

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        ringingChannelId,
        'Adhan playing',
        description: 'Shown while the full adhan is playing',
        importance: Importance.max,
        playSound: false,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    bool granted = true;
    if (Platform.isAndroid) {
      final notif = await Permission.notification.request();
      granted = granted && notif.isGranted;
      final exact = await Permission.scheduleExactAlarm.request();
      granted = granted && exact.isGranted;
    }
    return granted;
  }

  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.scheduleExactAlarm.isGranted;
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required bool useAdhanSound,
    required bool vibrate,
  }) async {
    if (useAdhanSound) {
      await AdhanAlarmService.scheduleAdhanAlarm(
        id: id,
        scheduledTime: scheduledDate.toLocal(),
        prayerLabel: title,
        vibrate: vibrate,
      );
      return;
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            alarmChannelId,
            'Prayer alarms',
            channelDescription: 'Alarm reminders for prayer times',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            playSound: true,
            enableVibration: vibrate,
            ongoing: false,
            autoCancel: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, st) {
      debugPrint('Failed to schedule alarm id=$id: $e\n$st');
    }
  }

  Future<void> scheduleWaqtPing({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
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
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, st) {
      debugPrint('Failed to schedule waqt ping id=$id: $e\n$st');
    }
  }

  Future<void> showRingingNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          ringingChannelId,
          'Adhan playing',
          channelDescription: 'Shown while the full adhan is playing',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
          ongoing: true,
          autoCancel: false,
          actions: [
            AndroidNotificationAction('stop_alarm', 'Stop', cancelNotification: true),
          ],
        ),
      ),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAllPrayerNotifications() async {
    const ids = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'chasht', 'tahajjud'];
    for (int idx = 0; idx < ids.length; idx++) {
      await _plugin.cancel(id: 100 + idx);
      await _plugin.cancel(id: 200 + idx);
      await AdhanAlarmService.cancel(100 + idx);
    }
  }

  Future<void> stopRingingAlarm(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> playPreview(String assetPath) async {
    await _previewPlayer.stop();
    await _previewPlayer.play(AssetSource(assetPath));
  }
}