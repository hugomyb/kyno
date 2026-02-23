class WorkoutSetLog {
  WorkoutSetLog({
    required this.setIndex,
    required this.reps,
    required this.seconds,
    required this.weight,
    required this.loadType,
    required this.loadMode,
    required this.rir,
  });

  final int setIndex;
  final int reps;
  final int seconds;
  final double weight;
  final String loadType;
  final String loadMode;
  final int? rir;

  Map<String, dynamic> toJson() {
    return {
      'set_index': setIndex,
      'reps': reps,
      'seconds': seconds,
      'weight': weight,
      'load_type': loadType,
      'load_mode': loadMode,
      'rir': rir,
    };
  }

  factory WorkoutSetLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSetLog(
      setIndex: (json['set_index'] as num?)?.toInt() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      loadType: (json['load_type'] as String?) ?? 'bodyweight',
      loadMode: (json['load_mode'] as String?) ?? 'total',
      rir: (json['rir'] as num?)?.toInt(),
    );
  }
}

class WorkoutExerciseLog {
  WorkoutExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  final String? exerciseId;
  final String exerciseName;
  final List<WorkoutSetLog> sets;

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutExerciseLog.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseLog(
      exerciseId: json['exercise_id'] as String?,
      exerciseName: (json['exercise_name'] as String?) ?? '',
      sets: (json['sets'] as List?)
              ?.map((e) => WorkoutSetLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <WorkoutSetLog>[],
    );
  }
}

class WorkoutSessionLog {
  WorkoutSessionLog({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.dateIso,
    required this.durationMinutes,
    required this.exerciseLogs,
  });

  final String id;
  final String? sessionId;
  final String name;
  final String dateIso;
  final int durationMinutes;
  final List<WorkoutExerciseLog> exerciseLogs;

  WorkoutSessionLog copyWith({
    String? name,
    String? dateIso,
    int? durationMinutes,
    List<WorkoutExerciseLog>? exerciseLogs,
  }) {
    return WorkoutSessionLog(
      id: id,
      sessionId: sessionId,
      name: name ?? this.name,
      dateIso: dateIso ?? this.dateIso,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'name': name,
      'date_iso': dateIso,
      'duration_minutes': durationMinutes,
      'exercises': exerciseLogs.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutSessionLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLog(
      id: json['id'] as String,
      sessionId: json['session_id'] as String?,
      name: (json['name'] as String?) ?? '',
      dateIso: (json['date_iso'] as String?) ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      exerciseLogs: (json['exercises'] as List?)
              ?.map((e) => WorkoutExerciseLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['exercise_logs'] as List?)
                  ?.map((e) => WorkoutExerciseLog.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              <WorkoutExerciseLog>[],
    );
  }
}

class ActiveWorkout {
  ActiveWorkout({
    required this.session,
    required this.exerciseIndex,
    required this.setIndex,
    required this.restRemaining,
    required this.workRemaining,
    required this.countdownRemaining,
    required this.elapsedSeconds,
    required this.startedAtIso,
    required this.paused,
  });

  final WorkoutSessionLog session;
  final int exerciseIndex;
  final int setIndex;
  final int restRemaining;
  final int workRemaining;
  final int countdownRemaining;
  final int elapsedSeconds;
  final String startedAtIso;
  final bool paused;

  Map<String, dynamic> toJson() {
    return {
      'workout_session_id': session.id,
      'exercise_index': exerciseIndex,
      'set_index': setIndex,
      'rest_remaining': restRemaining,
      'work_remaining': workRemaining,
      'countdown_remaining': countdownRemaining,
      'elapsed_seconds': elapsedSeconds,
      'started_at_iso': startedAtIso,
      'paused': paused,
    };
  }

  factory ActiveWorkout.fromJson(Map<String, dynamic> json) {
    return ActiveWorkout(
      session: WorkoutSessionLog.fromJson(
        json['workout_session'] as Map<String, dynamic>,
      ),
      exerciseIndex: (json['exercise_index'] as num?)?.toInt() ?? 0,
      setIndex: (json['set_index'] as num?)?.toInt() ?? 0,
      restRemaining: (json['rest_remaining'] as num?)?.toInt() ?? 0,
      workRemaining: (json['work_remaining'] as num?)?.toInt() ?? 0,
      countdownRemaining: (json['countdown_remaining'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      startedAtIso: (json['started_at_iso'] as String?) ?? '',
      paused: (json['paused'] as bool?) ?? false,
    );
  }
}
