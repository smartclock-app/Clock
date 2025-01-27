part of 'config.dart';

class DataSync {
  final bool isHost;
  final String hostUri;

  DataSync({
    required this.isHost,
    required this.hostUri,
  });

  factory DataSync.asDefault() => DataSync(
        isHost: true,
        hostUri: '',
      );

  factory DataSync.fromJson(Map<String, dynamic> json) => DataSync(
        isHost: json["isHost"],
        hostUri: json["hostUri"],
      );

  Map<String, dynamic> toJson() => {
        "isHost": isHost,
        "hostUri": hostUri,
      };
}
