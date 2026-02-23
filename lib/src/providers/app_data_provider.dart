import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/equipment.dart';
import '../models/exercise.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/session.dart';
import '../models/session_template.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

class AppData {
  AppData({
    required this.profile,
    required this.weightEntries,
    required this.equipment,
    required this.exercises,
    required this.sessions,
    required this.program,
    required this.workoutSessions,
    required this.activeWorkout,
  });

  final Profile profile;
  final List<WeightEntry> weightEntries;
  final List<Equipment> equipment;
  final List<Exercise> exercises;
  final List<TrainingSessionTemplate> sessions;
  final Program program;
  final List<WorkoutSessionLog> workoutSessions;
  final ActiveWorkout? activeWorkout;

  AppData copyWith({
    Profile? profile,
    List<WeightEntry>? weightEntries,
    List<Equipment>? equipment,
    List<Exercise>? exercises,
    List<TrainingSessionTemplate>? sessions,
    Program? program,
    List<WorkoutSessionLog>? workoutSessions,
    ActiveWorkout? activeWorkout,
  }) {
    return AppData(
      profile: profile ?? this.profile,
      weightEntries: weightEntries ?? this.weightEntries,
      equipment: equipment ?? this.equipment,
      exercises: exercises ?? this.exercises,
      sessions: sessions ?? this.sessions,
      program: program ?? this.program,
      workoutSessions: workoutSessions ?? this.workoutSessions,
      activeWorkout: activeWorkout ?? this.activeWorkout,
    );
  }

  factory AppData.empty() {
    return AppData(
      profile: Profile(
        id: 'profile',
        name: '',
        heightCm: 0,
        weightKg: 0,
        armLength: 'normal',
        femurLength: 'normal',
        limitations: <String>[],
        goal: '',
        startTimerSeconds: 5,
        soundEnabled: true,
        weightHistory: <WeightEntry>[],
      ),
      weightEntries: <WeightEntry>[],
      equipment: <Equipment>[],
      exercises: <Exercise>[],
      sessions: <TrainingSessionTemplate>[],
      program: Program(id: 'program', title: 'Programme', notes: '', days: <ProgramDay>[]),
      workoutSessions: <WorkoutSessionLog>[],
      activeWorkout: null,
    );
  }
}

final appDataProvider = NotifierProvider<AppDataNotifier, AppData>(
  AppDataNotifier.new,
);

class AppDataNotifier extends Notifier<AppData> {
  late ApiService api;
  final _uuid = const Uuid();

  @override
  AppData build() {
    api = ref.watch(apiServiceProvider);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasAuthed = previous?.isAuthenticated ?? false;
      if (!wasAuthed && next.isAuthenticated) {
        loadAll();
      }
      if (wasAuthed && !next.isAuthenticated) {
        state = AppData.empty();
      }
    });

    if (authState.isAuthenticated) {
      Future.microtask(loadAll);
    }

    return AppData.empty();
  }

  Future<void> loadAll() async {
    try {
      final results = await Future.wait([
        api.fetchProfile(),
        api.fetchWeights(),
        api.fetchEquipment(),
        api.fetchExercises(),
        api.fetchSessions(),
        api.fetchProgram(),
        api.fetchWorkoutSessions(),
        api.fetchActiveWorkout(),
      ]);

      state = state.copyWith(
        profile: (results[0] as Profile).copyWith(
          weightHistory: results[1] as List<WeightEntry>,
        ),
        weightEntries: results[1] as List<WeightEntry>,
        equipment: results[2] as List<Equipment>,
        exercises: results[3] as List<Exercise>,
        sessions: results[4] as List<TrainingSessionTemplate>,
        program: results[5] as Program,
        workoutSessions: results[6] as List<WorkoutSessionLog>,
        activeWorkout: results[7] as ActiveWorkout?,
      );
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
    } on ApiException {
      // Keep current state on transient API errors.
    }
  }

  Future<List<Exercise>> searchExercises(String query) async {
    try {
      return await api.fetchExercises(query: query);
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
      return <Exercise>[];
    }
  }

  Future<List<String>> fetchExerciseCategories() async {
    try {
      return await api.fetchExerciseCategories();
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
      return <String>[];
    }
  }

  Future<void> refreshExercises() async {
    try {
      state = state.copyWith(exercises: await api.fetchExercises());
    } catch (_) {}
  }

  Future<void> refreshSessions() async {
    try {
      state = state.copyWith(sessions: await api.fetchSessions());
    } catch (_) {}
  }

  Future<void> refreshProgram() async {
    try {
      state = state.copyWith(program: await api.fetchProgram());
    } catch (_) {}
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      final updated = await api.updateProfile(profile);
      state = state.copyWith(
        profile: updated.copyWith(weightHistory: state.weightEntries),
      );
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
    }
  }

  Future<void> addWeightEntry(double weightKg, {DateTime? date}) async {
    final now = date ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final entry = WeightEntry(
      dateIso: day.toIso8601String(),
      weightKg: weightKg,
    );
    await api.addWeight(entry);
    final updatedWeights = [...state.weightEntries];
    final existingIndex = updatedWeights.indexWhere(
      (e) => _sameDayIso(e.dateIso, entry.dateIso),
    );
    if (existingIndex >= 0) {
      updatedWeights[existingIndex] = entry;
    } else {
      updatedWeights.add(entry);
    }
    state = state.copyWith(
      weightEntries: updatedWeights,
      profile: state.profile.copyWith(weightHistory: updatedWeights),
    );
  }

  bool _sameDayIso(String a, String b) {
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) return a == b;
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  Future<void> addEquipment(String name, String notes) async {
    final equipment = Equipment(id: _uuid.v4(), name: name, notes: notes);
    await api.addEquipment(equipment);
    state = state.copyWith(equipment: [...state.equipment, equipment]);
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await api.updateEquipment(equipment);
    final updated = state.equipment
        .map((e) => e.id == equipment.id ? equipment : e)
        .toList();
    state = state.copyWith(equipment: updated);
  }

  Future<void> removeEquipment(String id) async {
    await api.deleteEquipment(id);
    state = state.copyWith(
      equipment: state.equipment.where((e) => e.id != id).toList(),
    );
  }

  Future<Exercise?> addExercise(
    String name, {
    List<String>? categories,
  }) async {
    try {
      final created = await api.addExercise(
        Exercise(
          id: _uuid.v4(),
          name: name,
          categories: categories ?? const <String>[],
        ),
      );
      state = state.copyWith(exercises: [...state.exercises, created]);
      return created;
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
      rethrow;
    }
  }

  Future<void> removeExercise(String id) async {
    await api.deleteExercise(id);
    state = state.copyWith(
      exercises: state.exercises.where((e) => e.id != id).toList(),
    );
  }

  Future<TrainingSessionTemplate> saveSession(TrainingSessionTemplate session) async {
    final existing = state.sessions.any((s) => s.id == session.id);
    final updated = existing
        ? await api.updateSession(session)
        : await api.createSession(session);

    final sessions = [...state.sessions];
    final index = sessions.indexWhere((s) => s.id == updated.id);
    if (index >= 0) {
      sessions[index] = updated;
    } else {
      sessions.add(updated);
    }
    state = state.copyWith(sessions: sessions);
    return updated;
  }

  Future<void> deleteSession(String id) async {
    final program = state.program;
    final hasInProgram = program.days.any((d) => d.sessionId == id);
    if (hasInProgram) {
      final updatedProgram = Program(
        id: program.id,
        title: program.title,
        notes: program.notes,
        days: program.days.where((d) => d.sessionId != id).toList(),
      );
      final saved = await api.updateProgram(updatedProgram);
      state = state.copyWith(program: saved);
    }
    await api.deleteSession(id);
    state = state.copyWith(sessions: state.sessions.where((s) => s.id != id).toList());
  }

  Future<void> updateProgram(Program program) async {
    final updated = await api.updateProgram(program);
    state = state.copyWith(program: updated);
  }

  Future<void> addWorkoutSession(WorkoutSessionLog session) async {
    final created = await api.createWorkoutSession(session);
    state = state.copyWith(workoutSessions: [...state.workoutSessions, created]);
  }

  Future<void> updateWorkoutSession(WorkoutSessionLog session) async {
    final updated = await api.updateWorkoutSession(session);
    final list = state.workoutSessions
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    state = state.copyWith(workoutSessions: list);
  }

  Future<void> setActiveWorkout(ActiveWorkout? activeWorkout) async {
    if (activeWorkout == null) {
      await api.clearActiveWorkout();
      state = state.copyWith(activeWorkout: null);
      return;
    }

    final updated = await api.updateActiveWorkout(activeWorkout);
    state = state.copyWith(activeWorkout: updated);
  }
}
