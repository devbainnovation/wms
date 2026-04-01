import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDeviceInfoService {
  const AppDeviceInfoService();

  Future<String> buildDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = _buildVersion(packageInfo);
    return '${_platformName()}, $version';
  }

  bool get shouldAttachFcmToken =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _buildVersion(PackageInfo packageInfo) {
    final versionName = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();

    if (versionName.isEmpty && buildNumber.isEmpty) {
      return 'unknown';
    }

    if (buildNumber.isEmpty) {
      return versionName;
    }

    if (versionName.isEmpty) {
      return buildNumber;
    }

    return '$versionName+$buildNumber';
  }
}
