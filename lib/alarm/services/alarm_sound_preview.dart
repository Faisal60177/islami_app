import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:muslim_app/alarm/services/ringer_mode_service.dart';
import '../model/alarm_settings_model.dart';

class AlarmSoundPreview {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(AlarmSoundType type) async {
    await stop();
    switch (type) {
      case AlarmSoundType.silent:
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (!hasVibrator) return;

        RingerMode mode = RingerMode.unknown;
        try {
          mode = await RingerModeService.getCurrentMode();
        } catch (_) {
          mode = RingerMode.normal;
        }
        if (mode != RingerMode.silent) {
          Vibration.vibrate(duration: 800);
        }
        break;
      case AlarmSoundType.beep:
        await _player.play(AssetSource('sounds/beep.mp3'));
        break;
      case AlarmSoundType.adhan:
        await _player.play(AssetSource('sounds/adhan.mp3'));
        break;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await Vibration.cancel();
  }

  void dispose() {
    _player.dispose();
  }
}