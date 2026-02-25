import 'friend.dart';
import 'session_template.dart';

class SharedSession {
  SharedSession({
    required this.id,
    required this.sender,
    required this.session,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final Friend sender;
  final TrainingSessionTemplate session;
  final String status; // 'pending', 'accepted', 'rejected'
  final String createdAt;

  factory SharedSession.fromJson(Map<String, dynamic> json) {
    return SharedSession(
      id: json['id'].toString(),
      sender: Friend.fromJson(json['sender'] as Map<String, dynamic>),
      session: TrainingSessionTemplate.fromJson(json['session'] as Map<String, dynamic>),
      status: (json['status'] as String?) ?? 'pending',
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'session': session.toJson(),
      'status': status,
      'created_at': createdAt,
    };
  }
}

