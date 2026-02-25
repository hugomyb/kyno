import '../models/equipment.dart';
import '../models/exercise.dart';
import '../models/friend.dart';
import '../models/notification.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/session.dart';
import '../models/session_template.dart';
import '../models/shared_session.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class ApiService {
  ApiService(this._client);

  final ApiClient _client;
  static const String _base = '/api/v1';

  Future<Profile> fetchProfile() async {
    final res = await _client.get('$_base/profile');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Profile failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Profile.fromJson(json['profile'] as Map<String, dynamic>);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final res = await _client.put('$_base/profile', profile.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Profile failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Profile.fromJson(json['profile'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _client.put('$_base/profile/password', {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    });
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) {
      String message = 'Password update failed';
      try {
        final json = _client.decodeJson(res.body) as Map<String, dynamic>;
        if (json['message'] != null) {
          message = json['message'].toString();
        }
        if (json['errors'] is Map) {
          final errors = json['errors'] as Map;
          final first = errors.values.cast<List>().expand((e) => e).cast<String?>().firstWhere(
                (e) => e != null && e.trim().isNotEmpty,
                orElse: () => null,
              );
          if (first != null) {
            message = first;
          }
        }
      } catch (_) {}
      throw ApiException(message, res.statusCode);
    }
  }

  Future<List<WeightEntry>> fetchWeights() async {
    final res = await _client.get('$_base/weight-entries');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Weights failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['weights'] as List?)
            ?.map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <WeightEntry>[];
  }

  Future<void> addWeight(WeightEntry entry) async {
    final res = await _client.post('$_base/weight-entries', entry.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 201) throw ApiException('Weights failed', res.statusCode);
  }

  Future<void> deleteWeight(String id) async {
    final res = await _client.delete('$_base/weight-entries/$id');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Weights failed', res.statusCode);
  }

  Future<List<Equipment>> fetchEquipment() async {
    final res = await _client.get('$_base/equipment');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Equipment failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['equipment'] as List?)
            ?.map((e) => Equipment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Equipment>[];
  }

  Future<void> addEquipment(Equipment equipment) async {
    final res = await _client.post('$_base/equipment', equipment.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 201) throw ApiException('Equipment failed', res.statusCode);
  }

  Future<void> updateEquipment(Equipment equipment) async {
    final res = await _client.put('$_base/equipment/${equipment.id}', {
      'name': equipment.name,
      'notes': equipment.notes,
    });
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Equipment failed', res.statusCode);
  }

  Future<void> deleteEquipment(String id) async {
    final res = await _client.delete('$_base/equipment/$id');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Equipment failed', res.statusCode);
  }

  Future<List<Exercise>> fetchExercises({String? query}) async {
    var path = '$_base/exercises';
    final trimmed = query?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      path = '$path?q=${Uri.encodeQueryComponent(trimmed)}';
    }
    final res = await _client.get(path);
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Exercises failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['exercises'] as List?)
            ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Exercise>[];
  }

  Future<List<String>> fetchExerciseCategories() async {
    final res = await _client.get('$_base/exercises/categories');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Exercise categories failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
  }

  Future<Exercise> addExercise(Exercise exercise) async {
    final res = await _client.post('$_base/exercises', exercise.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 201) {
      String message = 'Exercises failed';
      try {
        final json = _client.decodeJson(res.body) as Map<String, dynamic>;
        if (json['message'] != null) {
          message = json['message'].toString();
        }
        if (json['errors'] is Map) {
          final errors = json['errors'] as Map;
          final first = errors.values.cast<List>().expand((e) => e).cast<String?>().firstWhere(
                (e) => e != null && e.trim().isNotEmpty,
                orElse: () => null,
              );
          if (first != null) {
            message = first;
          }
        }
      } catch (_) {}
      throw ApiException(message, res.statusCode);
    }
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Exercise.fromJson(json['exercise'] as Map<String, dynamic>);
  }

  Future<void> deleteExercise(String id) async {
    final res = await _client.delete('$_base/exercises/$id');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Exercises failed', res.statusCode);
  }

  Future<List<TrainingSessionTemplate>> fetchSessions() async {
    final res = await _client.get('$_base/sessions');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Sessions failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['sessions'] as List?)
            ?.map((e) => TrainingSessionTemplate.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <TrainingSessionTemplate>[];
  }

  Future<TrainingSessionTemplate> fetchSession(String id) async {
    final res = await _client.get('$_base/sessions/$id');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Session failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return TrainingSessionTemplate.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<TrainingSessionTemplate> createSession(TrainingSessionTemplate session) async {
    final res = await _client.post('$_base/sessions', session.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 201) throw ApiException('Session failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return TrainingSessionTemplate.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<TrainingSessionTemplate> updateSession(TrainingSessionTemplate session) async {
    final res = await _client.put('$_base/sessions/${session.id}', session.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Session failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return TrainingSessionTemplate.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async {
    final res = await _client.delete('$_base/sessions/$id');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Session failed', res.statusCode);
  }

  Future<Program> fetchProgram() async {
    final res = await _client.get('$_base/program');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Program failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Program.fromJson(json['program'] as Map<String, dynamic>);
  }

  Future<Program> updateProgram(Program program) async {
    final res = await _client.put('$_base/program', program.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Program failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Program.fromJson(json['program'] as Map<String, dynamic>);
  }

  Future<List<WorkoutSessionLog>> fetchWorkoutSessions() async {
    final res = await _client.get('$_base/workouts');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Workouts failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['sessions'] as List?)
            ?.map((e) => WorkoutSessionLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <WorkoutSessionLog>[];
  }

  Future<WorkoutSessionLog> createWorkoutSession(WorkoutSessionLog session) async {
    final res = await _client.post('$_base/workouts', session.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 201) throw ApiException('Workout failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return WorkoutSessionLog.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<WorkoutSessionLog> updateWorkoutSession(WorkoutSessionLog session) async {
    final res = await _client.put('$_base/workouts/${session.id}', session.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Workout failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return WorkoutSessionLog.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<void> deleteWorkoutSession(String id) async {
    final res = await _client.delete('$_base/workouts/$id');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Workout failed', res.statusCode);
  }

  Future<ActiveWorkout?> fetchActiveWorkout() async {
    final res = await _client.get('$_base/active-workout');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Active workout failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    if (json['active'] == null) return null;
    return ActiveWorkout.fromJson(json['active'] as Map<String, dynamic>);
  }

  Future<ActiveWorkout> updateActiveWorkout(ActiveWorkout active) async {
    final res = await _client.put('$_base/active-workout', active.toJson());
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Active workout failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return ActiveWorkout.fromJson(json['active'] as Map<String, dynamic>);
  }

  Future<void> clearActiveWorkout() async {
    final res = await _client.delete('$_base/active-workout');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Active workout failed', res.statusCode);
  }

  Future<List<User>> fetchUsers() async {
    final res = await _client.get('$_base/users');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Users failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['users'] as List?)
            ?.map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <User>[];
  }

  Future<Program> fetchUserProgram(String userId) async {
    final res = await _client.get('$_base/users/$userId/program');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode == 404) throw ApiException('Programme non trouvé', res.statusCode);
    if (res.statusCode != 200) throw ApiException('Program failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Program.fromJson(json['program'] as Map<String, dynamic>);
  }

  Future<Program> copyUserProgram(String userId) async {
    final res = await _client.post('$_base/users/$userId/program/copy', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode == 404) throw ApiException('Programme non trouvé', res.statusCode);
    if (res.statusCode != 200) throw ApiException('Copy failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return Program.fromJson(json['program'] as Map<String, dynamic>);
  }

  // Friends
  Future<Friend?> searchUserByEmail(String email) async {
    final res = await _client.post('$_base/friends/search', {'email': email});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode == 422) throw Exception('Email invalide');
    if (res.statusCode != 200) throw Exception('Erreur lors de la recherche');
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    if (json['user'] == null) return null;
    return Friend.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<List<Friend>> fetchFriends() async {
    final res = await _client.get('$_base/friends');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Friends failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['friends'] as List?)
            ?.map((e) => Friend.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Friend>[];
  }

  Future<void> sendFriendRequest(String friendId) async {
    final res = await _client.post('$_base/friends/request', {'receiver_id': friendId});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode == 400) {
      final json = _client.decodeJson(res.body) as Map<String, dynamic>;
      final message = json['message'] as String?;
      if (message == 'Already friends') {
        throw Exception('Vous êtes déjà ami avec cet utilisateur');
      } else if (message == 'Request already sent') {
        throw Exception('Une demande d\'ami est déjà en attente');
      }
      throw Exception('Impossible d\'envoyer la demande');
    }
    if (res.statusCode != 201) throw Exception('Erreur lors de l\'envoi de la demande');
  }

  Future<List<FriendRequest>> fetchFriendRequests() async {
    final res = await _client.get('$_base/friends/requests');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Requests failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['requests'] as List?)
            ?.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <FriendRequest>[];
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final res = await _client.post('$_base/friends/requests/$requestId/accept', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Accept failed', res.statusCode);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final res = await _client.post('$_base/friends/requests/$requestId/reject', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Reject failed', res.statusCode);
  }

  Future<void> removeFriend(String friendId) async {
    final res = await _client.delete('$_base/friends/$friendId');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Remove failed', res.statusCode);
  }

  // Notifications
  Future<List<AppNotification>> fetchNotifications() async {
    final res = await _client.get('$_base/notifications');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Notifications failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['notifications'] as List?)
            ?.map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <AppNotification>[];
  }

  Future<int> fetchUnreadNotificationsCount() async {
    final res = await _client.get('$_base/notifications/unread-count');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Count failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final res = await _client.post('$_base/notifications/$notificationId/read', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Mark read failed', res.statusCode);
  }

  Future<void> markAllNotificationsAsRead() async {
    final res = await _client.post('$_base/notifications/read-all', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Mark all read failed', res.statusCode);
  }

  Future<void> deleteNotification(String notificationId) async {
    final res = await _client.delete('$_base/notifications/$notificationId');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Delete failed', res.statusCode);
  }

  // Session Sharing
  Future<void> shareSession(String sessionId, String friendId) async {
    final res = await _client.post('$_base/sessions/share', {
      'session_id': sessionId,
      'friend_id': friendId,
    });
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 201) throw ApiException('Share failed', res.statusCode);
  }

  Future<List<SharedSession>> fetchSharedSessions() async {
    final res = await _client.get('$_base/sessions/shared');
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Shared sessions failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return (json['shares'] as List?)
            ?.map((e) => SharedSession.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <SharedSession>[];
  }

  Future<TrainingSessionTemplate> acceptSharedSession(String sharedSessionId) async {
    final res = await _client.post('$_base/sessions/shared/$sharedSessionId/accept', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Accept failed', res.statusCode);
    final json = _client.decodeJson(res.body) as Map<String, dynamic>;
    return TrainingSessionTemplate.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<void> rejectSharedSession(String sharedSessionId) async {
    final res = await _client.post('$_base/sessions/shared/$sharedSessionId/reject', {});
    if (res.statusCode == 401) throw UnauthorizedException('Unauthorized');
    if (res.statusCode != 200) throw ApiException('Reject failed', res.statusCode);
  }
}
