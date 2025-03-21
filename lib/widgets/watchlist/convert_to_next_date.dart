import 'package:smartclock/widgets/watchlist/trakt_manager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

DateTime convertToNextDate(ShowAirs showAirs, String targetTimezone) {
  // Initialize timezone database
  tz_data.initializeTimeZones();

  // Parse the day and time
  String dayOfWeek = showAirs.day;
  String timeString = showAirs.time;
  String sourceTimezone = showAirs.timezone;

  // Get current time in source timezone
  final sourceLocation = tz.getLocation(sourceTimezone);
  final now = tz.TZDateTime.now(sourceLocation);

  // Parse the time (hours and minutes)
  List<String> timeParts = timeString.split(':');
  int hour = int.parse(timeParts[0]);
  int minute = int.parse(timeParts[1]);

  // Map day of week to int (1 = Monday, 7 = Sunday)
  Map<String, int> dayMap = {"Monday": 1, "Tuesday": 2, "Wednesday": 3, "Thursday": 4, "Friday": 5, "Saturday": 6, "Sunday": 7};

  int targetDayNum = dayMap[dayOfWeek]!;
  int currentDayNum = now.weekday;

  // Calculate days to add to reach the next occurrence of target day
  int daysToAdd = targetDayNum - currentDayNum;
  if (daysToAdd <= 0 || (daysToAdd == 0 && (now.hour > hour || (now.hour == hour && now.minute >= minute)))) {
    daysToAdd += 7; // Move to next week if today's target time has passed or day is in the past
  }

  // Create the next target date in source timezone
  final nextTargetDateSource = tz.TZDateTime(sourceLocation, now.year, now.month, now.day + daysToAdd, hour, minute);

  // Convert to target timezone
  final targetLocation = tz.getLocation(targetTimezone);
  final nextTargetDateTarget = tz.TZDateTime.from(nextTargetDateSource, targetLocation);

  // Convert TZDateTime to standard DateTime
  return DateTime(
    nextTargetDateTarget.year,
    nextTargetDateTarget.month,
    nextTargetDateTarget.day,
    nextTargetDateTarget.hour,
    nextTargetDateTarget.minute,
    nextTargetDateTarget.second,
    nextTargetDateTarget.millisecond,
    nextTargetDateTarget.microsecond,
  );
}

// // Example usage
// void main() {
//   Map<String, String> schedule = {
//     "day": "Friday",
//     "time": "03:00",
//     "timezone": "America/New_York"
//   };
  
//   DateTime nextDate = convertToNextDate(schedule, "Europe/London");
//   print("Next occurrence in London: $nextDate");
  
//   // You can now use it with any timezone
//   DateTime nextDateTokyo = convertToNextDate(schedule, "Asia/Tokyo");
//   print("Next occurrence in Tokyo: $nextDateTokyo");
// }