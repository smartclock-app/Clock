part of 'config.dart';

class HomeAssistant {
  final bool enabled;
  final String url;
  final String token;

  HomeAssistant({
    required this.enabled,
    required this.url,
    required this.token,
  });

  factory HomeAssistant.asDefault() => HomeAssistant(
        enabled: false,
        url: "",
        token: "",
      );

  factory HomeAssistant.fromJson(Map<String, dynamic> json) => HomeAssistant(
        enabled: json["enabled"],
        url: json["url"],
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "url": url,
        "token": token,
      };
}
