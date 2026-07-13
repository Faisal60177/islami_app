import 'package:audioplayers/audioplayers.dart';
import '../model/alarm_settings_model.dart';

class AlarmSoundPreview {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(AlarmSoundType type) async {
    await stop();
    switch (type) {
      case AlarmSoundType.silent:
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
  }

  void dispose() {
    _player.dispose();
  }
}