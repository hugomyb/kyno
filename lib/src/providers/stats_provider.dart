import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import 'app_data_provider.dart';

class UserStats {
  const UserStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.avgMinutes,
    required this.totalExercises,
    required this.totalSets,
    required this.totalVolume,
    required this.activeDays,
    required this.topExercise,
  });

  final int totalSessions;
  final int totalMinutes;
  final double avgMinutes;
  final int totalExercises;
  final int totalSets;
  final double totalVolume;
  final int activeDays;
  final String? topExercise;

  factory UserStats.fromWorkouts(List<WorkoutSessionLog> workouts) {
    final totalSessions = workouts.length;
    final totalMinutes = workouts.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final avgMinutes = totalSessions == 0 ? 0.0 : (totalMinutes / totalSessions);
    final totalExercises = workouts.fold<int>(
      0,
      (sum, session) => sum + session.exerciseLogs.length,
    );
    final totalSets = workouts.fold<int>(
      0,
      (sum, session) => sum +
          session.exerciseLogs.fold<int>(
            0,
            (inner, log) => inner + log.sets.length,
          ),
    );
    final totalVolume = workouts.fold<double>(
      0,
      (sum, session) => sum +
          session.exerciseLogs.fold<double>(
            0,
            (inner, log) => inner +
                log.sets.fold<double>(
                  0,
                  (setSum, set) => setSum + (set.weight * set.reps.toDouble()),
                ),
          ),
    );

    final uniqueDays = <String>{};
    final exerciseCounts = <String, int>{};
    for (final session in workouts) {
      final date = DateTime.tryParse(session.dateIso);
      if (date != null) {
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        uniqueDays.add(key);
      }
      for (final log in session.exerciseLogs) {
        final name = log.exerciseName.trim();
        if (name.isEmpty) continue;
        exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
      }
    }

    String? topExercise;
    int topCount = 0;
    exerciseCounts.forEach((name, count) {
      if (count > topCount) {
        topCount = count;
        topExercise = name;
      }
    });

    return UserStats(
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      avgMinutes: avgMinutes,
      totalExercises: totalExercises,
      totalSets: totalSets,
      totalVolume: totalVolume,
      activeDays: uniqueDays.length,
      topExercise: topExercise,
    );
  }
}

final userStatsProvider = Provider<UserStats>((ref) {
  final workouts = ref.watch(appDataProvider.select((s) => s.workoutSessions));
  return UserStats.fromWorkouts(workouts);
});
