part of 'config.dart';

class DataSync {
  final bool enabled;
  final bool isHost;
  final String hostUri;

  DataSync({
    required this.enabled,
    required this.isHost,
    required this.hostUri,
  });

  factory DataSync.asDefault() => DataSync(
        enabled: false,
        isHost: false,
        hostUri: '',
      );

  factory DataSync.fromJson(Map<String, dynamic> json) => DataSync(
        enabled: json["enabled"],
        isHost: json["isHost"],
        hostUri: json["hostUri"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "isHost": isHost,
        "hostUri": hostUri,
      };
}
