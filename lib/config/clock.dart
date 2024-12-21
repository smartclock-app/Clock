part of 'config.dart';

class Clock {
  final bool twentyFourHour;
  final bool showSeconds;
  final double mainSize;
  final double smallSize;
  final double smallGap;
  final double dateSize;
  final double dateGap;
  final double padding;

  Clock({
    required this.twentyFourHour,
    required this.showSeconds,
    required this.mainSize,
    required this.smallSize,
    required this.smallGap,
    required this.dateSize,
    required this.dateGap,
    required this.padding,
  });

  factory Clock.asDefault() => Clock(
        twentyFourHour: false,
        showSeconds: true,
        mainSize: 200,
        smallSize: 85,
        smallGap: 15,
        dateSize: 48,
        dateGap: 50,
        padding: 16,
      );

  factory Clock.fromJson(Map<String, dynamic> json) => Clock(
        twentyFourHour: json["twentyFourHour"],
        showSeconds: json["showSeconds"],
        mainSize: double.parse(json["mainSize"].toString()),
        smallSize: double.parse(json["smallSize"].toString()),
        smallGap: double.parse(json["smallGap"].toString()),
        dateSize: double.parse(json["dateSize"].toString()),
        dateGap: double.parse(json["dateGap"].toString()),
        padding: double.parse(json["padding"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "twentyFourHour": twentyFourHour,
        "showSeconds": showSeconds,
        "mainSize": mainSize,
        "smallSize": smallSize,
        "smallGap": smallGap,
        "dateSize": dateSize,
        "dateGap": dateGap,
        "padding": padding,
      };
}
