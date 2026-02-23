import 'exercise.dart';

class TrainingSessionTemplate {
  TrainingSessionTemplate({
    required this.id,
    required this.name,
    required this.notes,
    required this.groups,
  });

  final String id;
  final String name;
  final String? notes;
  final List<SessionGroup> groups;

  factory TrainingSessionTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingSessionTemplate(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      notes: json['notes'] as String?,
      groups: (json['groups'] as List?)
              ?.map((e) => SessionGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <SessionGroup>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'groups': groups.map((e) => e.toJson()).toList(),
    };
  }
}

class SessionGroup {
  SessionGroup({
    required this.orderIndex,
    required this.rounds,
    required this.restBetweenRoundsSeconds,
    required this.exercises,
  });

  final int orderIndex;
  final int rounds;
  final int restBetweenRoundsSeconds;
  final List<SessionExerciseConfig> exercises;

  factory SessionGroup.fromJson(Map<String, dynamic> json) {
    return SessionGroup(
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      rounds: (json['rounds'] as num?)?.toInt() ?? 1,
      restBetweenRoundsSeconds:
          (json['rest_between_rounds_seconds'] as num?)?.toInt() ?? 0,
      exercises: (json['exercises'] as List?)
              ?.map((e) => SessionExerciseConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <SessionExerciseConfig>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_index': orderIndex,
      'rounds': rounds,
      'rest_between_rounds_seconds': restBetweenRoundsSeconds,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class SessionExerciseConfig {
  SessionExerciseConfig({
    required this.exerciseId,
    required this.orderIndex,
    required this.targetType,
    required this.targetReps,
    required this.targetSeconds,
    required this.restSeconds,
    required this.loadType,
    required this.loadValue,
    required this.loadMode,
    required this.notes,
    this.exercise,
  });

  final String exerciseId;
  final int orderIndex;
  final String targetType;
  final int targetReps;
  final int targetSeconds;
  final int restSeconds;
  final String loadType;
  final double loadValue;
  final String loadMode;
  final String? notes;
  final Exercise? exercise;

  bool get isTimed => targetType == 'time';

  factory SessionExerciseConfig.fromJson(Map<String, dynamic> json) {
    return SessionExerciseConfig(
      exerciseId: json['exercise_id'] as String,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      targetType: (json['target_type'] as String?) ?? 'reps',
      targetReps: (json['target_reps'] as num?)?.toInt() ?? 0,
      targetSeconds: (json['target_seconds'] as num?)?.toInt() ?? 0,
      restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 0,
      loadType: (json['load_type'] as String?) ?? 'bodyweight',
      loadValue: (json['load_value'] as num?)?.toDouble() ?? 0,
      loadMode: (json['load_mode'] as String?) ?? 'total',
      notes: json['notes'] as String?,
      exercise: json['exercise'] == null
          ? null
          : Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'target_type': targetType,
      'target_reps': targetReps,
      'target_seconds': targetSeconds,
      'rest_seconds': restSeconds,
      'load_type': loadType,
      'load_value': loadValue,
      'load_mode': loadMode,
      'notes': notes,
    };
  }
}
