class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type; // 'friend_request' or 'session_shared'
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      data: json['data'] as Map<String, dynamic>?,
      read: (json['read'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'read': read,
      'created_at': createdAt,
    };
  }
}

