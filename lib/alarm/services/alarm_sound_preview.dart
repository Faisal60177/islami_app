import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../model/alarm_settings_model.dart';

class AlarmSoundPreview {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(AlarmSoundType type) async {
    await stop();
    switch (type) {
      case AlarmSoundType.silent:
        break;
      case AlarmSoundType.systemDefault:
      // Placeholder preview — a real device-ringtone picker needs
      // native platform channels, not available from pure Dart plugins.
        SystemSound.play(SystemSoundType.alert);
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