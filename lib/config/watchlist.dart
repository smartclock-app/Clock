part of 'config.dart';

class Watchlist {
  final bool enabled;
  final Trakt trakt;
  final String prefix;
  final Color color;
  final int maxItems;

  Watchlist({
    required this.enabled,
    required this.trakt,
    required this.prefix,
    required this.color,
    required this.maxItems,
  });

  factory Watchlist.asDefault() => Watchlist(
        enabled: false,
        trakt: Trakt.asDefault(),
        prefix: "Watchlist: ",
        color: "#f5511d".toColor(),
        maxItems: 4,
      );

  factory Watchlist.fromJson(Map<String, dynamic> json) => Watchlist(
        enabled: json["enabled"],
        trakt: Trakt.fromJson(json["trakt"]),
        prefix: json["prefix"],
        color: (json["color"] as String).toColor(),
        maxItems: json["maxItems"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "trakt": trakt.toJson(),
        "prefix": prefix,
        "color": color.toHex(),
        "maxItems": maxItems,
      };
}
