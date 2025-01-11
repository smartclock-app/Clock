part of 'config.dart';

class Sidebar {
  final bool enabled;
  final double cardRadius;
  final Color cardColor;
  final double titleSize;
  final double headingSize;
  final double subheadingSize;

  Sidebar({
    required this.enabled,
    required this.cardRadius,
    required this.cardColor,
    required this.titleSize,
    required this.headingSize,
    required this.subheadingSize,
  });

  factory Sidebar.asDefault() => Sidebar(
        enabled: true,
        cardRadius: 10,
        cardColor: "#f8f8f8".toColor(),
        titleSize: 36,
        headingSize: 34,
        subheadingSize: 28,
      );

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        enabled: json["enabled"],
        cardRadius: double.parse(json["cardRadius"].toString()),
        cardColor: (json["cardColor"] as String).toColor(),
        titleSize: double.parse(json["titleSize"].toString()),
        headingSize: double.parse(json["headingSize"].toString()),
        subheadingSize: double.parse(json["subheadingSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "cardRadius": cardRadius,
        "cardColor": cardColor.toHex(),
        "titleSize": titleSize,
        "headingSize": headingSize,
        "subheadingSize": subheadingSize,
      };
}
