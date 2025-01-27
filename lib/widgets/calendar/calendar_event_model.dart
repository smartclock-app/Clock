// widgets/calendar/calendar_event_model.dart
class CalendarEventModel {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String color; // Store color as hex string instead of Color object

  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });

  // From JSON constructor
  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'],
      title: json['title'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      color: json['color'],
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'color': color,
    };
  }
}
