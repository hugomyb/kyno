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
    required this.order,
  });

  final String id;
  final String name;
  final List<ExerciseTemplate> exercises;
  final int restSeconds;
  final int order;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'restSeconds': restSeconds,
      'order': order,
    };
  }

  factory WorkoutSessionTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionTemplate(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Session',
      exercises: (json['exercises'] as List?)
              ?.map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <ExerciseTemplate>[],
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
      order: (json['order'] as num?)?.toInt() ?? 0,
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
    required this.tempo,
    required this.notes,
    required this.restSeconds,
  });

  final String id;
  final String name;
  final int sets;
  final String targetReps;
  final double targetWeight;
  final String tempo;
  final String notes;
  final int restSeconds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'tempo': tempo,
      'notes': notes,
      'restSeconds': restSeconds,
    };
  }

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Exercice',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      targetReps: (json['targetReps'] as String?) ?? '8-12',
      targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 0,
      tempo: (json['tempo'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
    );
  }
}
