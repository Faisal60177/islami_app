import 'package:package_info_plus/package_info_plus.dart';

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
    return _info.version;
  }

  static String get buildNumber {
    assert(_initialized, 'AppInfo.init() must be called before use');
    return _info.buildNumber;
  }

  static String get appName {
    assert(_initialized, 'AppInfo.init() must be called before use');
    return _info.appName;
  }

  static String get versionWithBuild => 'Version $version (Build $buildNumber)';
}