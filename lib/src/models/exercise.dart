class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.categories,
    this.userId,
  });

  final String id;
  final String name;
  final List<String> categories;
  final String? userId;

  bool get isGlobal => userId == null;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories.map((e) => e.toString()).toList()
        : <String>[];
    return Exercise(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      categories: categories,
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categories': categories,
    };
  }
}
