class TrainingProgram {
  TrainingProgram({
    required this.id,
    required this.title,
    required this.notes,
    required this.days,
  });

  final String id;
  final String title;
  final String notes;
  final List<ProgramDay> days;

  factory TrainingProgram.fromJson(Map<String, dynamic> json) {
    return TrainingProgram(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      days: (json['days'] as List?)
              ?.map((d) => ProgramDay.fromJson(d as Map<String, dynamic>))
              .toList() ??
          <ProgramDay>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  TrainingProgram copyWith({
    String? title,
    String? notes,
    List<ProgramDay>? days,
  }) {
    return TrainingProgram(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      days: days ?? this.days,
    );
  }
}

class ProgramDay {
  ProgramDay({
    required this.id,
    required this.dayOfWeek,
    required this.sessionId,
    required this.orderIndex,
  });

  final int? id;
  final int dayOfWeek;
  final String? sessionId;
  final int orderIndex;

  factory ProgramDay.fromJson(Map<String, dynamic> json) {
    return ProgramDay(
      id: (json['id'] as num?)?.toInt(),
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      sessionId: json['session_id'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'session_id': sessionId,
      'order_index': orderIndex,
    };
  }

  ProgramDay copyWith({
    String? sessionId,
    int? orderIndex,
  }) {
    return ProgramDay(
      id: id,
      dayOfWeek: dayOfWeek,
      sessionId: sessionId ?? this.sessionId,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
