part of 'config.dart';

class Watchlist {
  final bool enabled;
  final Trakt trakt;
  final String tmdbApiKey;
  final String timezone;
  final String prefix;
  final Color color;
  final int maxItems;

  Watchlist({
    required this.enabled,
    required this.trakt,
    required this.tmdbApiKey,
    required this.timezone,
    required this.prefix,
    required this.color,
    required this.maxItems,
  });

  factory Watchlist.asDefault() => Watchlist(
        enabled: false,
        trakt: Trakt.asDefault(),
        tmdbApiKey: "",
        timezone: "Europe/London",
        prefix: "Watchlist: ",
        color: "#f5511d".toColor(),
        maxItems: 4,
      );

  factory Watchlist.fromJson(Map<String, dynamic> json) => Watchlist(
        enabled: json["enabled"],
        trakt: Trakt.fromJson(json["trakt"]),
        tmdbApiKey: json["tmdbApiKey"],
        timezone: json["timezone"],
        prefix: json["prefix"],
        color: (json["color"] as String).toColor(),
        maxItems: json["maxItems"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "trakt": trakt.toJson(),
        "tmdbApiKey": tmdbApiKey,
        "timezone": timezone,
        "prefix": prefix,
        "color": color.toHex(),
        "maxItems": maxItems,
      };
}
