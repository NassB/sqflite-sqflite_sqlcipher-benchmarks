class DeviceMetadata {
  const DeviceMetadata({
    required this.device,
    required this.os,
    required this.osVersion,
    required this.appVersion,
    required this.buildMode,
  });

  final String device;
  final String os;
  final String osVersion;
  final String appVersion;
  final String buildMode;

  Map<String, dynamic> toJson() => {
        'device': device,
        'os': os,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'buildMode': buildMode,
      };

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) {
    return DeviceMetadata(
      device: json['device'] as String,
      os: json['os'] as String,
      osVersion: json['osVersion'] as String,
      appVersion: json['appVersion'] as String,
      buildMode: json['buildMode'] as String,
    );
  }
}
