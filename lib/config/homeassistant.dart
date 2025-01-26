part of 'config.dart';

class HomeAssistant {
  final bool enabled;
  final String url;
  final String token;
  final List<Camera> cameras;
  final int cameraWaitTime;

  HomeAssistant({
    required this.enabled,
    required this.url,
    required this.token,
    required this.cameras,
    required this.cameraWaitTime,
  });

  factory HomeAssistant.asDefault() => HomeAssistant(
        enabled: false,
        url: "",
        token: "",
        cameras: [],
        cameraWaitTime: 30,
      );

  factory HomeAssistant.fromJson(Map<String, dynamic> json) => HomeAssistant(
        enabled: json["enabled"],
        url: json["url"],
        token: json["token"],
        cameras: List<Camera>.from(json["cameras"].map((x) => Camera.fromJson(x))),
        cameraWaitTime: json["cameraWaitTime"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "url": url,
        "token": token,
        "cameras": List<dynamic>.from(cameras.map((x) => x.toJson())),
        "cameraWaitTime": cameraWaitTime,
      };
}

class Camera {
  final String id;
  final String trigger;
  final String? streamUri;
  final double aspectRatio;

  Camera({
    required this.id,
    required this.trigger,
    required this.streamUri,
    required this.aspectRatio,
  });

  factory Camera.fromJson(Map<String, dynamic> json) => Camera(
        id: json["id"],
        trigger: json["trigger"],
        streamUri: json["streamUri"],
        aspectRatio: double.parse(json["aspectRatio"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "trigger": trigger,
        "streamUri": streamUri,
        "aspectRatio": aspectRatio,
      };
}
