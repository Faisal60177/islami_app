import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:muslim_app/alarm/services/ringer_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../model/alarm_settings_model.dart';
import 'notification_service.dart';

const String _pendingAlarmKey = 'pending_ringing_alarm';
String _stopSignalKey(int id) => 'ring_stop_signal_$id';

const Duration _maxRingDuration = Duration(minutes: 1);

String _assetFor(AlarmSoundType type) {
  switch (type) {
    case AlarmSoundType.adhan: return 'sounds/adhan.mp3';
    case AlarmSoundType.beep:  return 'sounds/beep.mp3';
    case AlarmSoundType.silent: return '';
  }
}

// FIX: checks the phone's physical ringer switch before vibrating.
// Silent mode → stay fully silent, no vibration at all.
// Vibrate or Normal/Ring mode → vibrate as before.

Future<bool> _shouldVibrate(bool vibrateWanted) async {
  if (!vibrateWanted) return false;
  final hasVibrator = await Vibration.hasVibrator() ?? false;
  if (!hasVibrator) return false;

  RingerMode mode = RingerMode.unknown;
  try {
    mode = await RingerModeService.getCurrentMode();
  } catch (_) {
    mode = RingerMode.normal;
  }
  return mode != RingerMode.silent;
}

@pragma('vm:entry-point')
Future<void> alarmRingCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prayerLabel = params['prayerLabel'] as String? ?? 'Prayer';
  final soundTypeIndex = params['soundType'] as int? ?? AlarmSoundType.adhan.index;
  final soundType = AlarmSoundType.values[soundTypeIndex];
  final vibrate = params['vibrate'] as bool? ?? true;

  await NotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_stopSignalKey(id));
  await prefs.setString(_pendingAlarmKey, jsonEncode({
    'id': id,
    'prayerLabel': prayerLabel,
    'startedAt': DateTime.now().toIso8601String(),
  }));

  await NotificationService.instance.showRingingNotification(
    id: id,
    title: '$prayerLabel — Prayer time',
    body: 'Tap to open, or Stop to end',
  );

  AudioPlayer? player;
  Timer? stopPoll;
  Timer? maxDurationTimer;
  bool stopped = false;

  Future<void> stopEverything() async {
    if (stopped) return;
    stopped = true;
    stopPoll?.cancel();
    maxDurationTimer?.cancel();
    await player?.stop();
    await player?.dispose();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.cancel();
    }
    await NotificationService.instance.cancel(id);
    await prefs.remove(_pendingAlarmKey);
    await prefs.remove(_stopSignalKey(id));
  }

  stopPoll = Timer.periodic(const Duration(milliseconds: 300), (_) async {
    await prefs.reload();
    final stopRequested = prefs.getBool(_stopSignalKey(id)) ?? false;
    if (stopRequested) {
      await stopEverything();
    }
  });

  switch (soundType) {
    case AlarmSoundType.adhan:
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      player.onPlayerComplete.listen((_) => stopEverything());
      try {
        await player.play(AssetSource(_assetFor(soundType)));
      } catch (e) {
        debugPrint('Adhan playback failed for id=$id: $e');
        await stopEverything();
      }
      break;

    case AlarmSoundType.beep:
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      try {
        await player.play(AssetSource(_assetFor(soundType)));
        maxDurationTimer = Timer(_maxRingDuration, stopEverything);
      } catch (e) {
        debugPrint('Beep playback failed for id=$id: $e');
        await stopEverything();
      }
      break;

    case AlarmSoundType.silent:
      if (await _shouldVibrate(vibrate)) {
        Vibration.vibrate(pattern: [500, 1000], repeat: 0);
      }
      maxDurationTimer = Timer(_maxRingDuration, stopEverything);
      break;
  }
}

class AlarmRingService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleRingAlarm({
    required int id,
    required DateTime scheduledTime,
    required String prayerLabel,
    required AlarmSoundType soundType,
    required bool vibrate,
  }) async {
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      id,
      alarmRingCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'prayerLabel': prayerLabel,
        'soundType': soundType.index,
        'vibrate': vibrate,
      },
    );
  }

  static Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stopSignalKey(id));
  }

  static Future<void> requestStop(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stopSignalKey(id), true);
    await prefs.remove(_pendingAlarmKey);
    await NotificationService.instance.cancel(id);
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.cancel();
    }
  }

  static Future<Map<String, dynamic>?> getPendingAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_pendingAlarmKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}