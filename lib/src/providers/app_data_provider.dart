import 'dart:async';
import 'dart:convert';

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
import '../services/storage_service.dart';
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
        streak: 0,
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
  late StorageService storage;
  final _uuid = const Uuid();
  bool _didHydrateFromCache = false;

  @override
  AppData build() {
    api = ref.watch(apiServiceProvider);
    storage = ref.watch(storageProvider);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasAuthed = previous?.isAuthenticated ?? false;
      if (!wasAuthed && next.isAuthenticated) {
        _didHydrateFromCache = false;
        _hydrateFromCache();
        loadAll();
      }
      if (wasAuthed && !next.isAuthenticated) {
        state = AppData.empty();
        _didHydrateFromCache = false;
        unawaited(storage.delete(StorageService.appDataCacheKey));
      }
    });

    if (authState.isAuthenticated && !_didHydrateFromCache) {
      _didHydrateFromCache = true;
      _hydrateFromCache();
    }

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
      unawaited(_persistCache());
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
    } on ApiException {
      // Keep cached/current state on transient API errors.
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
      unawaited(_persistCache());
    } catch (_) {}
  }

  Future<void> refreshSessions() async {
    try {
      state = state.copyWith(sessions: await api.fetchSessions());
      unawaited(_persistCache());
    } catch (_) {}
  }

  Future<void> refreshProgram() async {
    try {
      state = state.copyWith(program: await api.fetchProgram());
      unawaited(_persistCache());
    } catch (_) {}
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      final updated = await api.updateProfile(profile);
      state = state.copyWith(
        profile: updated.copyWith(weightHistory: state.weightEntries),
      );
      unawaited(_persistCache());
    } on UnauthorizedException {
      await ref.read(authProvider.notifier).forceLogout();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
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
    unawaited(_persistCache());
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
    unawaited(_persistCache());
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await api.updateEquipment(equipment);
    final updated = state.equipment
        .map((e) => e.id == equipment.id ? equipment : e)
        .toList();
    state = state.copyWith(equipment: updated);
    unawaited(_persistCache());
  }

  Future<void> removeEquipment(String id) async {
    await api.deleteEquipment(id);
    state = state.copyWith(
      equipment: state.equipment.where((e) => e.id != id).toList(),
    );
    unawaited(_persistCache());
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
      unawaited(_persistCache());
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
    unawaited(_persistCache());
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
    unawaited(_persistCache());
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
      unawaited(_persistCache());
    }
    await api.deleteSession(id);
    state = state.copyWith(sessions: state.sessions.where((s) => s.id != id).toList());
    unawaited(_persistCache());
  }

  Future<void> updateProgram(Program program) async {
    final updated = await api.updateProgram(program);
    state = state.copyWith(program: updated);
    unawaited(_persistCache());
  }

  Future<void> addWorkoutSession(WorkoutSessionLog session) async {
    final created = await api.createWorkoutSession(session);
    state = state.copyWith(workoutSessions: [...state.workoutSessions, created]);
    unawaited(_persistCache());
  }

  Future<void> updateWorkoutSession(WorkoutSessionLog session) async {
    final updated = await api.updateWorkoutSession(session);
    final list = state.workoutSessions
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    state = state.copyWith(workoutSessions: list);
    unawaited(_persistCache());
  }

  Future<void> setActiveWorkout(ActiveWorkout? activeWorkout) async {
    if (activeWorkout == null) {
      await api.clearActiveWorkout();
      state = state.copyWith(activeWorkout: null);
      unawaited(_persistCache());
      return;
    }

    final updated = await api.updateActiveWorkout(activeWorkout);
    state = state.copyWith(activeWorkout: updated);
    unawaited(_persistCache());
  }

  void _hydrateFromCache() {
    final raw = storage.getString(StorageService.appDataCacheKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final profileJson = decoded['profile'];
      final programJson = decoded['program'];
      if (profileJson is! Map || programJson is! Map) {
        return;
      }
      state = AppData(
        profile: Profile.fromJson(
          profileJson.cast<String, dynamic>(),
        ),
        weightEntries: _decodeList(
          decoded['weight_entries'],
          (e) => WeightEntry.fromJson(e),
        ),
        equipment: _decodeList(
          decoded['equipment'],
          (e) => Equipment.fromJson(e),
        ),
        exercises: _decodeList(
          decoded['exercises'],
          (e) => Exercise.fromJson(e),
        ),
        sessions: _decodeList(
          decoded['sessions'],
          (e) => TrainingSessionTemplate.fromJson(e),
        ),
        program: Program.fromJson(
          programJson.cast<String, dynamic>(),
        ),
        workoutSessions: _decodeList(
          decoded['workout_sessions'],
          (e) => WorkoutSessionLog.fromJson(e),
        ),
        activeWorkout: null,
      );
    } catch (_) {
      // Ignore corrupted cache.
    }
  }

  Future<void> _persistCache() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      return;
    }

    final payload = <String, dynamic>{
      'profile': state.profile.toJson(),
      'weight_entries': state.weightEntries.map((e) => e.toJson()).toList(),
      'equipment': state.equipment.map((e) => e.toJson()).toList(),
      'exercises': state.exercises.map((e) => e.toJson()).toList(),
      'sessions': state.sessions.map((e) => e.toJson()).toList(),
      'program': state.program.toJson(),
      'workout_sessions': state.workoutSessions.map((e) => e.toJson()).toList(),
    };

    await storage.setString(StorageService.appDataCacheKey, jsonEncode(payload));
  }

  List<T> _decodeList<T>(
    dynamic source,
    T Function(Map<String, dynamic>) decoder,
  ) {
    if (source is! List) {
      return <T>[];
    }
    final result = <T>[];
    for (final item in source) {
      if (item is Map) {
        result.add(decoder(item.cast<String, dynamic>()));
      }
    }
    return result;
  }
}
