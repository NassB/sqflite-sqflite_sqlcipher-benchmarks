import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/utils/build_mode.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/device_metadata.dart';

class DeviceMetadataService {
  const DeviceMetadataService();

  Future<DeviceMetadata> load() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String device = 'unknown';
    String osVersion = 'unknown';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      device = '${info.manufacturer} ${info.model}';
      osVersion = 'Android ${info.version.release}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      device = '${info.name} ${info.model}';
      osVersion = 'iOS ${info.systemVersion}';
    }

    return DeviceMetadata(
      device: device,
      os: Platform.operatingSystem,
      osVersion: osVersion,
      appVersion: packageInfo.version,
      buildMode: detectBuildMode(),
    );
  }
}
