class WorkoutProgram {
  WorkoutProgram({
    required this.id,
    required this.title,
    required this.sessions,
    required this.notes,
  });

  final String id;
  final String title;
  final List<WorkoutSessionTemplate> sessions;
  final String notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    return WorkoutProgram(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Programme',
      sessions: (json['sessions'] as List?)
              ?.map((e) => WorkoutSessionTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <WorkoutSessionTemplate>[],
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

class WorkoutSessionTemplate {
  WorkoutSessionTemplate({
    required this.id,
    required this.name,
    required this.exercises,
    required this.restSeconds,
    required this.estimatedDurationSeconds,
    required this.order,
    required this.dayOfWeek,
  });

  final String id;
  final String name;
  final List<ExerciseTemplate> exercises;
  final int restSeconds;
  final int estimatedDurationSeconds;
  final int order;
  final int dayOfWeek;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'restSeconds': restSeconds,
      'estimatedDurationSeconds': estimatedDurationSeconds,
      'order': order,
      'dayOfWeek': dayOfWeek,
    };
  }

  factory WorkoutSessionTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionTemplate(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Seance',
      exercises: (json['exercises'] as List?)
              ?.map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <ExerciseTemplate>[],
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
      estimatedDurationSeconds:
          (json['estimatedDurationSeconds'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
    );
  }
}

class ExerciseTemplate {
  ExerciseTemplate({
    required this.id,
    required this.name,
    required this.sets,
    required this.targetReps,
    required this.targetWeight,
    required this.loadText,
    required this.tempo,
    required this.notes,
    required this.restSeconds,
    required this.isTimed,
    required this.durationSeconds,
  });

  final String id;
  final String name;
  final int sets;
  final String targetReps;
  final double targetWeight;
  final String loadText;
  final String tempo;
  final String notes;
  final int restSeconds;
  final bool isTimed;
  final int durationSeconds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'loadText': loadText,
      'tempo': tempo,
      'notes': notes,
      'restSeconds': restSeconds,
      'isTimed': isTimed,
      'durationSeconds': durationSeconds,
    };
  }

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Exercice',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      targetReps: (json['targetReps'] as String?) ?? '8-12',
      targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 0,
      loadText: (json['loadText'] as String?) ?? '',
      tempo: (json['tempo'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
      isTimed: (json['isTimed'] as bool?) ?? false,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
