import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/streak.dart';
import 'app_data_provider.dart';

final streakProvider = Provider<int>((ref) {
  final program = ref.watch(appDataProvider.select((s) => s.program));
  final workouts = ref.watch(appDataProvider.select((s) => s.workoutSessions));
  return calculateProgramStreak(program, workouts);
});
