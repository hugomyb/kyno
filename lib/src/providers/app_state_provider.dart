import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_state.dart';
import '../models/equipment.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/session.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

class AppStateNotifier extends Notifier<AppState> {
  late StorageService storage;
  final _uuid = const Uuid();

  @override
  AppState build() {
    storage = ref.watch(storageProvider);
    final loaded = storage.loadState();
    state = loaded.copyWith(lastOpenIso: DateTime.now().toIso8601String());
    storage.saveState(state);
    return state;
  }

  Future<void> save() async {
    await storage.saveState(state);
  }

  void updateProfile(Profile profile) {
    state = state.copyWith(profile: profile);
  }

  void addWeightEntry(double weightKg, {DateTime? date}) {
    final now = date ?? DateTime.now();
    final entry = WeightEntry(
      dateIso: now.toIso8601String(),
      weightKg: weightKg,
    );
    final updated = state.profile.copyWith(
      weightKg: weightKg,
      weightHistory: [...state.profile.weightHistory, entry],
    );
    state = state.copyWith(profile: updated);
  }

  void markAppOpened() {
    state = state.copyWith(lastOpenIso: DateTime.now().toIso8601String());
  }

  void updateProgram(WorkoutProgram program) {
    state = state.copyWith(program: program);
  }

  void updateExercise({
    required String sessionId,
    required String exerciseId,
    required ExerciseTemplate updated,
  }) {
    final sessions = state.program.sessions.map((session) {
      if (session.id != sessionId) return session;
      final exercises = session.exercises
          .map((exercise) => exercise.id == exerciseId ? updated : exercise)
          .toList();
      return WorkoutSessionTemplate(
        id: session.id,
        name: session.name,
        exercises: exercises,
        restSeconds: session.restSeconds,
        estimatedDurationSeconds: session.estimatedDurationSeconds,
        order: session.order,
        dayOfWeek: session.dayOfWeek,
      );
    }).toList();
    state = state.copyWith(
      program: WorkoutProgram(
        id: state.program.id,
        title: state.program.title,
        sessions: sessions,
        notes: state.program.notes,
      ),
    );
  }

  void addEquipment(String name, String notes) {
    final equipment = List.of(state.equipment)
      ..add(Equipment(id: _uuid.v4(), name: name, notes: notes));
    state = state.copyWith(equipment: equipment);
  }

  void updateEquipmentList(List<Equipment> equipment) {
    state = state.copyWith(equipment: equipment);
  }

  void removeEquipment(String id) {
    final equipment = state.equipment.where((e) => e.id != id).toList();
    state = state.copyWith(equipment: equipment);
  }

  void addSession(WorkoutSession session) {
    final sessions = List.of(state.sessions)..add(session);
    state = state.copyWith(sessions: sessions);
  }

  void updateSession(WorkoutSession session) {
    final sessions = state.sessions.map((s) => s.id == session.id ? session : s).toList();
    state = state.copyWith(sessions: sessions);
  }

  void updateSessionList(List<WorkoutSession> sessions) {
    state = state.copyWith(sessions: sessions);
  }

  void setActiveWorkout(ActiveWorkout activeWorkout) {
    state = state.copyWith(activeWorkout: activeWorkout);
  }

  void clearActiveWorkout() {
    state = state.copyWith(activeWorkout: null);
  }

  void replaceAll({required AppState merged}) {
    state = merged;
  }

  WorkoutSession startSession(WorkoutSessionTemplate template) {
    return WorkoutSession(
      id: _uuid.v4(),
      templateId: template.id,
      name: template.name,
      dateIso: DateTime.now().toIso8601String(),
      durationMinutes: 0,
      exerciseLogs: template.exercises
          .map(
            (e) => SessionExerciseLog(
              exerciseId: e.id,
              exerciseName: e.name,
              sets: List.generate(
                e.sets,
                (index) => SessionSetLog(
                  setIndex: index + 1,
                  reps: e.isTimed ? e.durationSeconds : 0,
                  weight: e.targetWeight,
                  rir: null,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
