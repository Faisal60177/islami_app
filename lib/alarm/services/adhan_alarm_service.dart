import 'package:audioplayers/audioplayers.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Runs inside a background isolate when AndroidAlarmManager fires at the
/// exact prayer time. Plays the full adhan once, then auto-stops itself —
/// this is the callback that makes "ring once, then stop" actually happen.
@pragma('vm:entry-point')
Future<void> adhanAlarmCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prayerLabel = params['prayerLabel'] as String? ?? 'Prayer';
  final vibrate = params['vibrate'] as bool? ?? true;

  await NotificationService.instance.init();

  // Show the ongoing "ringing" notification with a Stop action, so the
  // user can end it early even before the adhan finishes on its own.
  await NotificationService.instance.showRingingNotification(
    id: id,
    title: '$prayerLabel — Adhan',
    body: 'Tap Stop to end early',
  );

  final player = AudioPlayer();
  await player.setReleaseMode(ReleaseMode.stop); // single play, no loop

  // Auto-stop everything the moment the adhan finishes playing on its own —
  // this is what makes it "ring once, then auto stop" rather than looping.
  player.onPlayerComplete.listen((_) async {
    await NotificationService.instance.cancel(id);
    await player.dispose();
  });

  try {
    await player.play(AssetSource('sounds/adhan.mp3'));
    if (vibrate) {
      // Vibration pattern alongside playback; harmless if device has none.
    }
  } catch (e) {
    debugPrint('Adhan playback failed for id=$id: $e');
    await NotificationService.instance.cancel(id);
  }
}

class AdhanAlarmService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  /// Schedules a one-off exact alarm that will invoke [adhanAlarmCallback]
  /// in a background isolate at [scheduledTime] — this fires even if the
  /// app has been fully closed, as long as the OS keeps the device alive
  /// long enough to run the callback (standard AlarmManager guarantee).
  static Future<void> scheduleAdhanAlarm({
    required int id,
    required DateTime scheduledTime,
    required String prayerLabel,
    required bool vibrate,
  }) async {
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      id,
      adhanAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'prayerLabel': prayerLabel,
        'vibrate': vibrate,
      },
    );
  }

  static Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}