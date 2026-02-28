import 'dart:convert';

enum PendingWorkoutStage { countdown, running }

class PendingWorkoutState {
  PendingWorkoutState({
    required this.sessionId,
    required this.sessionName,
    required this.stage,
    required this.currentStepIndex,
    required this.remainingSeconds,
    required this.elapsedSeconds,
    required this.paused,
  });

  final String sessionId;
  final String sessionName;
  final PendingWorkoutStage stage;
  final int currentStepIndex;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool paused;

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'session_name': sessionName,
      'stage': stage.name,
      'current_step_index': currentStepIndex,
      'remaining_seconds': remainingSeconds,
      'elapsed_seconds': elapsedSeconds,
      'paused': paused,
    };
  }

  String toStorageString() => jsonEncode(toJson());

  static PendingWorkoutState? fromStorageString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final sessionId = (decoded['session_id'] as String?)?.trim() ?? '';
      final sessionName = (decoded['session_name'] as String?)?.trim() ?? '';
      final stageRaw = decoded['stage'] as String?;
      if (sessionId.isEmpty || sessionName.isEmpty || stageRaw == null) return null;
      PendingWorkoutStage? stage;
      for (final value in PendingWorkoutStage.values) {
        if (value.name == stageRaw) {
          stage = value;
          break;
        }
      }
      if (stage == null) return null;

      return PendingWorkoutState(
        sessionId: sessionId,
        sessionName: sessionName,
        stage: stage,
        currentStepIndex: (decoded['current_step_index'] as num?)?.toInt() ?? 0,
        remainingSeconds: (decoded['remaining_seconds'] as num?)?.toInt() ?? 0,
        elapsedSeconds: (decoded['elapsed_seconds'] as num?)?.toInt() ?? 0,
        paused: (decoded['paused'] as bool?) ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
