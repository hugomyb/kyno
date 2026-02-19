class Equipment {
  Equipment({
    required this.id,
    required this.name,
    required this.notes,
  });

  final String id;
  final String name;
  final String notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
