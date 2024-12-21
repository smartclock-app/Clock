part of 'config.dart';

class Alexa {
  final bool enabled;
  final ({bool nowplaying, bool alarms, bool timers, bool notes}) features;
  final String userId;
  final String token;
  final List<String> devices;
  List<String>? radioProviders;
  final double nowplayingImageSize;
  final double nowplayingFontSize;
  final double lyricsCurrentFontSize;
  final double lyricsNextFontSize;
  final int noteColumns;
  final double noteFontSize;

  Alexa({
    required this.enabled,
    required this.features,
    required this.userId,
    required this.token,
    required this.devices,
    this.radioProviders,
    required this.nowplayingImageSize,
    required this.nowplayingFontSize,
    required this.lyricsCurrentFontSize,
    required this.lyricsNextFontSize,
    required this.noteColumns,
    required this.noteFontSize,
  });

  factory Alexa.asDefault() => Alexa(
        enabled: false,
        features: (
          nowplaying: false,
          alarms: false,
          timers: false,
          notes: false,
        ),
        userId: "",
        token: "",
        devices: [],
        nowplayingImageSize: 146,
        nowplayingFontSize: 32,
        lyricsCurrentFontSize: 24,
        lyricsNextFontSize: 20,
        noteColumns: 3,
        noteFontSize: 24,
      );

  factory Alexa.fromJson(Map<String, dynamic> json) => Alexa(
        enabled: json["enabled"],
        features: (
          nowplaying: json["features"]["nowplaying"],
          alarms: json["features"]["alarms"],
          timers: json["features"]["timers"],
          notes: json["features"]["notes"],
        ),
        userId: json["userId"],
        token: json["token"],
        devices: List<String>.from(json["devices"]),
        radioProviders: json["radioProviders"] != null ? List<String>.from(json["radioProviders"]) : null,
        nowplayingImageSize: double.parse(json["nowplayingImageSize"].toString()),
        nowplayingFontSize: double.parse(json["nowplayingFontSize"].toString()),
        lyricsCurrentFontSize: double.parse(json["lyricsCurrentFontSize"].toString()),
        lyricsNextFontSize: double.parse(json["lyricsNextFontSize"].toString()),
        noteColumns: json["noteColumns"],
        noteFontSize: double.parse(json["noteFontSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "features": {
          "nowplaying": features.nowplaying,
          "alarms": features.alarms,
          "timers": features.timers,
          "notes": features.notes,
        },
        "userId": userId,
        "token": token,
        "devices": List<dynamic>.from(devices),
        if (radioProviders != null) 'radioProviders': List<dynamic>.from(radioProviders!),
        "nowplayingImageSize": nowplayingImageSize,
        "nowplayingFontSize": nowplayingFontSize,
        "lyricsCurrentFontSize": lyricsCurrentFontSize,
        "lyricsNextFontSize": lyricsNextFontSize,
        "noteColumns": noteColumns,
        "noteFontSize": noteFontSize,
      };
}
