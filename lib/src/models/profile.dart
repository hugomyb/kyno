class Profile {
  Profile({
    required this.id,
    required this.name,
    required this.heightCm,
    required this.weightKg,
    required this.armLength,
    required this.femurLength,
    required this.limitations,
    required this.goal,
    required this.startTimerSeconds,
    required this.weightHistory,
  });

  final String id;
  final String name;
  final int heightCm;
  final double weightKg;
  final String armLength;
  final String femurLength;
  final List<String> limitations;
  final String goal;
  final int startTimerSeconds;
  final List<WeightEntry> weightHistory;

  Profile copyWith({
    String? name,
    int? heightCm,
    double? weightKg,
    String? armLength,
    String? femurLength,
    List<String>? limitations,
    String? goal,
    int? startTimerSeconds,
    List<WeightEntry>? weightHistory,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      armLength: armLength ?? this.armLength,
      femurLength: femurLength ?? this.femurLength,
      limitations: limitations ?? this.limitations,
      goal: goal ?? this.goal,
      startTimerSeconds: startTimerSeconds ?? this.startTimerSeconds,
      weightHistory: weightHistory ?? this.weightHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'arm_length': armLength,
      'femur_length': femurLength,
      'limitations': limitations,
      'goal': goal,
      'start_timer_seconds': startTimerSeconds,
      'weight_history': weightHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? 'profile',
      name: (json['name'] as String?) ?? '',
      heightCm: (json['height_cm'] as num?)?.toInt() ?? 0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
      armLength: (json['arm_length'] as String?) ?? 'normal',
      femurLength: (json['femur_length'] as String?) ?? 'normal',
      limitations: (json['limitations'] as List?)?.cast<String>() ?? <String>[],
      goal: (json['goal'] as String?) ?? '',
      startTimerSeconds: (json['start_timer_seconds'] as num?)?.toInt() ?? 5,
      weightHistory: (json['weight_history'] as List?)
              ?.map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <WeightEntry>[],
    );
  }
}

class WeightEntry {
  WeightEntry({
    this.id,
    required this.dateIso,
    required this.weightKg,
  });

  final String? id;
  final String dateIso;
  final double weightKg;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date_iso': dateIso,
      'weight_kg': weightKg,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id']?.toString(),
      dateIso: (json['date_iso'] as String?) ?? '',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}
