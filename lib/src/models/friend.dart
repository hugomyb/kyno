class Friend {
  Friend({
    required this.id,
    required this.name,
    required this.email,
    required this.streak,
  });

  final String id;
  final String name;
  final String email;
  final int streak;

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'streak': streak,
    };
  }
}

class FriendRequest {
  FriendRequest({
    required this.id,
    required this.sender,
    required this.createdAt,
  });

  final String id;
  final Friend sender;
  final String createdAt;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'].toString(),
      sender: Friend.fromJson(json['sender'] as Map<String, dynamic>),
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'created_at': createdAt,
    };
  }
}
