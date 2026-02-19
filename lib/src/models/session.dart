class SessionSetLog {
  SessionSetLog({
    required this.setIndex,
    required this.reps,
    required this.weight,
    required this.rir,
  });

  final int setIndex;
  final int reps;
  final double weight;
  final int? rir;

  Map<String, dynamic> toJson() {
    return {
      'setIndex': setIndex,
      'reps': reps,
      'weight': weight,
      'rir': rir,
    };
  }

  factory SessionSetLog.fromJson(Map<String, dynamic> json) {
    return SessionSetLog(
      setIndex: (json['setIndex'] as num?)?.toInt() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      rir: (json['rir'] as num?)?.toInt(),
    );
  }
}

class SessionExerciseLog {
  SessionExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  final String exerciseId;
  final String exerciseName;
  final List<SessionSetLog> sets;

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  factory SessionExerciseLog.fromJson(Map<String, dynamic> json) {
    return SessionExerciseLog(
      exerciseId: json['exerciseId'] as String,
      exerciseName: (json['exerciseName'] as String?) ?? '',
      sets: (json['sets'] as List?)
              ?.map((e) => SessionSetLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <SessionSetLog>[],
    );
  }
}

class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.templateId,
    required this.name,
    required this.dateIso,
    required this.durationMinutes,
    required this.exerciseLogs,
  });

  final String id;
  final String templateId;
  final String name;
  final String dateIso;
  final int durationMinutes;
  final List<SessionExerciseLog> exerciseLogs;

  WorkoutSession copyWith({
    String? name,
    String? dateIso,
    int? durationMinutes,
    List<SessionExerciseLog>? exerciseLogs,
  }) {
    return WorkoutSession(
      id: id,
      templateId: templateId,
      name: name ?? this.name,
      dateIso: dateIso ?? this.dateIso,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'name': name,
      'dateIso': dateIso,
      'durationMinutes': durationMinutes,
      'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      templateId: (json['templateId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      dateIso: (json['dateIso'] as String?) ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      exerciseLogs: (json['exerciseLogs'] as List?)
              ?.map((e) => SessionExerciseLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <SessionExerciseLog>[],
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

  final WorkoutSession session;
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
      'session': session.toJson(),
      'exerciseIndex': exerciseIndex,
      'setIndex': setIndex,
      'restRemaining': restRemaining,
      'workRemaining': workRemaining,
      'countdownRemaining': countdownRemaining,
      'elapsedSeconds': elapsedSeconds,
      'startedAtIso': startedAtIso,
      'paused': paused,
    };
  }

  factory ActiveWorkout.fromJson(Map<String, dynamic> json) {
    return ActiveWorkout(
      session: WorkoutSession.fromJson(json['session'] as Map<String, dynamic>),
      exerciseIndex: (json['exerciseIndex'] as num?)?.toInt() ?? 0,
      setIndex: (json['setIndex'] as num?)?.toInt() ?? 0,
      restRemaining: (json['restRemaining'] as num?)?.toInt() ?? 0,
      workRemaining: (json['workRemaining'] as num?)?.toInt() ?? 0,
      countdownRemaining: (json['countdownRemaining'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      startedAtIso: (json['startedAtIso'] as String?) ?? '',
      paused: (json['paused'] as bool?) ?? false,
    );
  }
}
