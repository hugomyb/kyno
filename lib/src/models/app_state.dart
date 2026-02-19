import 'equipment.dart';
import 'profile.dart';
import 'program.dart';
import 'session.dart';

class AppState {
  AppState({
    required this.profile,
    required this.equipment,
    required this.program,
    required this.sessions,
    required this.lastOpenIso,
    required this.activeWorkout,
  });

  final Profile profile;
  final List<Equipment> equipment;
  final WorkoutProgram program;
  final List<WorkoutSession> sessions;
  final String lastOpenIso;
  final ActiveWorkout? activeWorkout;

  AppState copyWith({
    Profile? profile,
    List<Equipment>? equipment,
    WorkoutProgram? program,
    List<WorkoutSession>? sessions,
    String? lastOpenIso,
    ActiveWorkout? activeWorkout,
  }) {
    return AppState(
      profile: profile ?? this.profile,
      equipment: equipment ?? this.equipment,
      program: program ?? this.program,
      sessions: sessions ?? this.sessions,
      lastOpenIso: lastOpenIso ?? this.lastOpenIso,
      activeWorkout: activeWorkout ?? this.activeWorkout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'program': program.toJson(),
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'lastOpenIso': lastOpenIso,
      'activeWorkout': activeWorkout?.toJson(),
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
      equipment: (json['equipment'] as List?)
              ?.map((e) => Equipment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Equipment>[],
      program: WorkoutProgram.fromJson(json['program'] as Map<String, dynamic>),
      sessions: (json['sessions'] as List?)
              ?.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <WorkoutSession>[],
      lastOpenIso: (json['lastOpenIso'] as String?) ?? '',
      activeWorkout: json['activeWorkout'] == null
          ? null
          : ActiveWorkout.fromJson(json['activeWorkout'] as Map<String, dynamic>),
    );
  }

  factory AppState.empty() {
    return AppState(
      profile: Profile(
        id: 'profile',
        name: '',
        heightCm: 0,
        weightKg: 0,
        armLength: 'normal',
        femurLength: 'normal',
        limitations: <String>[],
        goal: 'hypertrophy',
        weightHistory: <WeightEntry>[],
      ),
      equipment: <Equipment>[
        Equipment(id: 'eq_bench', name: 'Banc', notes: 'Incline/plat'),
        Equipment(id: 'eq_mat', name: 'Tapis', notes: ''),
        Equipment(id: 'eq_pushup_handles', name: 'Poignees pompes', notes: 'Deux poignees'),
        Equipment(
          id: 'eq_roman_chair',
          name: 'Chaise romaine',
          notes:
              'Chaise romaine murale, plusieurs poignees qui permettent d\'effectuer des exercices larges, a marteaux ou a prise serree, barre de dips, chaise pour abdos',
        ),
        Equipment(
          id: 'eq_dumbbells',
          name: 'Halteres',
          notes: 'Deux halteres, 20kg, max 10kg sur chaque en meme temps',
        ),
      ],
      program: WorkoutProgram(
        id: 'program',
        title: 'Programme Maison',
        sessions: <WorkoutSessionTemplate>[],
        notes: '',
      ),
      sessions: <WorkoutSession>[],
      lastOpenIso: '',
      activeWorkout: null,
    );
  }
}
