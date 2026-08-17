import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../models/click_mode.dart';

class FeedbackService {
  final AudioPlayer _audio = AudioPlayer();

  Future<void> playTick(ClickMode mode)async {
    switch(mode){
      case ClickMode.sound:
        await _audio.play(AssetSource('sounds/tasbih_click.mp3'));
        break;
        case ClickMode.vibrate:
          final has = await Vibration.hasVibrator();
          if(has ?? false) Vibration.vibrate(duration: 40);
          break;
          case ClickMode.mute:
            break;
    }
  }

  Future<void> playRoundComplete(ClickMode mode) async {
    switch(mode){
      case ClickMode.vibrate:
        final has = await Vibration.hasVibrator();
        if(has ?? false) Vibration.vibrate(duration: 600);
        break;
        case ClickMode.sound:
          await Future.delayed(const Duration(milliseconds: 300), () => _audio.resume());
          break;
          case ClickMode.mute:
            break;

    }
  }

  void dispose() => _audio.dispose();

}