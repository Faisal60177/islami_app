import 'package:flutter/services.dart';

enum RingerMode { silent, vibrate, normal, unknown }

class RingerModeService {
  static const _channel = MethodChannel('muslim_life/ringer_mode');

  static Future<RingerMode> getCurrentMode() async {
    try {
      final int modeValue = await _channel.invokeMethod('getRingerMode');
      switch (modeValue) {
        case 0: return RingerMode.silent;
        case 1: return RingerMode.vibrate;
        case 2: return RingerMode.normal;
        default: return RingerMode.unknown;
      }
    } catch (_) {
      return RingerMode.unknown;
    }
  }
}