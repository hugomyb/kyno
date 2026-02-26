import '../models/program.dart';
import '../models/session.dart';

int calculateProgramStreak(
  Program program,
  List<WorkoutSessionLog> workouts, {
  DateTime? today,
  int graceDays = 1,
}) {
  final scheduledWeekdays = program.days
      .where((day) => day.sessionId != null && day.sessionId!.isNotEmpty)
      .map((day) => day.dayOfWeek)
      .toSet();

  if (scheduledWeekdays.isEmpty) {
    return 0;
  }

  final workoutDateKeys = <int>{};
  for (final session in workouts) {
    final parsed = DateTime.tryParse(session.dateIso);
    if (parsed == null) continue;
    final local = parsed.toLocal();
    workoutDateKeys.add(_dateKey(local));
  }

  final now = (today ?? DateTime.now());
  final todayDate = DateTime(now.year, now.month, now.day);

  var streak = 0;
  var graceUsed = 0;
  const maxLookbackDays = 730;

  for (var offset = 0; offset < maxLookbackDays; offset++) {
    final date = todayDate.subtract(Duration(days: offset));
    final isScheduled = scheduledWeekdays.contains(date.weekday);

    final dateKey = _dateKey(date);
    final hasWorkout = workoutDateKeys.contains(dateKey);
    if (hasWorkout) {
      streak += 1;
    }

    if (isScheduled && !hasWorkout) {
      if (offset == 0) {
        // Don't break the streak during the scheduled day itself.
        continue;
      }

      if (graceUsed < graceDays) {
        graceUsed += 1;
        continue;
      }

      break;
    }
  }

  return streak;
}

int _dateKey(DateTime date) {
  return date.year * 10000 + date.month * 100 + date.day;
}
