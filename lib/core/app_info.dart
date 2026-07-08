import 'package:package_info_plus/package_info_plus.dart';

/// Call AppInfo.init() once in main() before runApp().
/// After that, use AppInfo.version / AppInfo.buildNumber anywhere,
/// synchronously, with no FutureBuilder needed.
class AppInfo {
  static late final PackageInfo _info;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _info = await PackageInfo.fromPlatform();
    _initialized = true;
  }

  static String get version {
    assert(_initialized, 'AppInfo.init() must be called before use');
    return _info.version; // e.g. "1.0.0"
  }

  static String get buildNumber {
    assert(_initialized, 'AppInfo.init() must be called before use');
    return _info.buildNumber; // e.g. "9"
  }

  static String get appName {
    assert(_initialized, 'AppInfo.init() must be called before use');
    return _info.appName;
  }

  /// Convenience combined string: "1.0.0 (Build 9)"
  static String get versionWithBuild => 'Version $version (Build $buildNumber)';
}