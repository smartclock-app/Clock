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
}
