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
  });

  final String id;
  final String name;
  final int heightCm;
  final double weightKg;
  final String armLength;
  final String femurLength;
  final List<String> limitations;
  final String goal;

  Profile copyWith({
    String? name,
    int? heightCm,
    double? weightKg,
    String? armLength,
    String? femurLength,
    List<String>? limitations,
    String? goal,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'armLength': armLength,
      'femurLength': femurLength,
      'limitations': limitations,
      'goal': goal,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      armLength: (json['armLength'] as String?) ?? 'normal',
      femurLength: (json['femurLength'] as String?) ?? 'normal',
      limitations: (json['limitations'] as List?)?.cast<String>() ?? <String>[],
      goal: (json['goal'] as String?) ?? 'hypertrophy',
    );
  }
}
