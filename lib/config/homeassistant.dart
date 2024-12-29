part of 'config.dart';

class HomeAssistant {
  final bool enabled;
  final String url;
  final String token;
  final List<Camera> cameras;

  HomeAssistant({
    required this.enabled,
    required this.url,
    required this.token,
    required this.cameras,
  });

  factory HomeAssistant.asDefault() => HomeAssistant(
        enabled: false,
        url: "",
        token: "",
        cameras: [],
      );

  factory HomeAssistant.fromJson(Map<String, dynamic> json) => HomeAssistant(
        enabled: json["enabled"],
        url: json["url"],
        token: json["token"],
        cameras: List<Camera>.from(json["cameras"].map((x) => Camera.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "url": url,
        "token": token,
        "cameras": List<dynamic>.from(cameras.map((x) => x.toJson())),
      };
}

class Camera {
  final String id;
  final String trigger;
  final double aspectRatio;

  Camera({
    required this.id,
    required this.trigger,
    required this.aspectRatio,
  });

  factory Camera.fromJson(Map<String, dynamic> json) => Camera(
        id: json["id"],
        trigger: json["trigger"],
        aspectRatio: double.parse(json["aspectRatio"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "trigger": trigger,
        "aspectRatio": aspectRatio,
      };
}
