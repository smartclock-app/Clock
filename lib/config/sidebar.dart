part of 'config.dart';

class Sidebar {
  final bool enabled;
  final double cardRadius;
  final Color cardColor;

  Sidebar({
    required this.enabled,
    required this.cardRadius,
    required this.cardColor,
  });

  factory Sidebar.asDefault() => Sidebar(
        enabled: true,
        cardRadius: 10,
        cardColor: "#f8f8f8".toColor(),
      );

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        enabled: json["enabled"],
        cardRadius: double.parse(json["cardRadius"].toString()),
        cardColor: (json["cardColor"] as String).toColor(),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "cardRadius": cardRadius,
        "cardColor": cardColor.toHex(),
      };
}
