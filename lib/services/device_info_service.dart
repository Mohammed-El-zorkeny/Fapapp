import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceAppInfo {
  const DeviceAppInfo({
    required this.deviceType,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });

  final String deviceType;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
}

class DeviceInfoService {
  DeviceInfoService._();

  static final DeviceInfoService instance = DeviceInfoService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  DeviceAppInfo? _cachedInfo;

  Future<DeviceAppInfo> getDeviceAppInfo({bool forceRefresh = false}) async {
    if (_cachedInfo != null && !forceRefresh) {
      return _cachedInfo!;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfo.androidInfo;
      _cachedInfo = DeviceAppInfo(
        deviceType: 'ANDROID',
        deviceModel: _formatAndroidModel(androidInfo),
        osVersion: 'Android ${androidInfo.version.release}',
        appVersion: appVersion,
      );
      return _cachedInfo!;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      _cachedInfo = DeviceAppInfo(
        deviceType: 'IOS',
        deviceModel: iosInfo.utsname.machine,
        osVersion: '${iosInfo.systemName} ${iosInfo.systemVersion}',
        appVersion: appVersion,
      );
      return _cachedInfo!;
    }

    _cachedInfo = DeviceAppInfo(
      deviceType: defaultTargetPlatform.name.toUpperCase(),
      deviceModel: 'UNKNOWN',
      osVersion: 'UNKNOWN',
      appVersion: appVersion,
    );
    return _cachedInfo!;
  }

  String _formatAndroidModel(AndroidDeviceInfo androidInfo) {
    final brand = androidInfo.brand.trim();
    final model = androidInfo.model.trim();

    if (brand.isEmpty) return model.isEmpty ? 'UNKNOWN' : model;
    if (model.toLowerCase().startsWith(brand.toLowerCase())) return model;
    return '$brand $model';
  }
}
