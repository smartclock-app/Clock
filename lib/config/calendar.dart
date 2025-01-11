part of 'config.dart';

class Calendar {
  final bool enabled;
  final int maxEvents;
  final ({String odd, String even}) titles;
  final List<String> eventFilter;
  final double eventColorWidth;

  Calendar({
    required this.enabled,
    required this.maxEvents,
    required this.titles,
    required this.eventFilter,
    required this.eventColorWidth,
  });

  factory Calendar.asDefault() => Calendar(
        enabled: false,
        maxEvents: 10,
        titles: (
          odd: "",
          even: "",
        ),
        eventFilter: [],
        eventColorWidth: 8,
      );

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        enabled: json["enabled"],
        maxEvents: json["maxEvents"],
        titles: (
          odd: json["titles"]["odd"],
          even: json["titles"]["even"],
        ),
        eventFilter: List<String>.from(json["eventFilter"]),
        eventColorWidth: double.parse(json["eventColorWidth"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "maxEvents": maxEvents,
        "titles": {
          "odd": titles.odd,
          "even": titles.even,
        },
        "eventFilter": List<dynamic>.from(eventFilter),
        "eventColorWidth": eventColorWidth,
      };
}
