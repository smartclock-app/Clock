part of 'config.dart';

class Energy {
  final bool enabled;
  final String token;
  final String gasId;
  final String electricityId;
  final double fontSize;
  final double iconSize;

  Energy({
    required this.enabled,
    required this.token,
    required this.gasId,
    required this.electricityId,
    required this.fontSize,
    required this.iconSize,
  });

  factory Energy.asDefault() => Energy(
        enabled: false,
        token: "",
        gasId: "",
        electricityId: "",
        fontSize: 32,
        iconSize: 50,
      );

  factory Energy.fromJson(Map<String, dynamic> json) => Energy(
        enabled: false, // TODO: Disable until better implementation, current api not useful.
        token: json["token"],
        gasId: json["gasId"],
        electricityId: json["electricityId"],
        fontSize: double.parse(json["fontSize"].toString()),
        iconSize: double.parse(json["iconSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "token": token,
        "gasId": gasId,
        "electricityId": electricityId,
        "fontSize": fontSize,
        "iconSize": iconSize,
      };
}
