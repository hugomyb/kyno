import '../models/program.dart';
import '../models/profile.dart';

class ProgramImportData {
  ProgramImportData({
    required this.program,
    required this.profile,
  });

  final WorkoutProgram program;
  final Profile? profile;
}

class ProgramImportService {
  ProgramImportData fromJson(Map<String, dynamic> json) {
    final days = (json['programme'] as List?) ?? <dynamic>[];
    final sessions = <WorkoutSessionTemplate>[];
    final meta = json['meta'] as Map<String, dynamic>?;
    final profile = _parseProfile(meta?['profil']);
    final notes = _buildNotes(meta);

    for (var i = 0; i < days.length; i++) {
      final map = days[i] as Map<String, dynamic>;
      final dayLabel = (map['jour'] as String?) ?? 'Jour';
      final focus = (map['focus'] as List?)?.cast<String>() ?? <String>[];
      final note = (map['note'] as String?) ?? '';
      final dayOfWeek = _dayOfWeekFromLabel(dayLabel);
      final focusLabel = focus.isEmpty ? dayLabel : focus.join(' / ');
      final title = note.isEmpty ? focusLabel : '$focusLabel ($note)';

      final rest = map['repos'] as Map<String, dynamic>?;
      final standardRest = _parseRestSeconds(rest?['standard']);
      final estimatedDurationSeconds =
          (map['duree_totale_estimee'] as num?)?.toInt() ?? 0;

      final exercisesJson = (map['exercices'] as List?) ?? <dynamic>[];
      final exercises = <ExerciseTemplate>[];
      for (final ex in exercisesJson) {
        final exMap = ex as Map<String, dynamic>;
        final name = (exMap['nom'] as String?) ?? 'Exercice';
        final sets = (exMap['series'] as num?)?.toInt() ?? 3;
        final repetitions = exMap['repetitions'];
        final duration = (exMap['duree'] as num?)?.toInt();
        final restSeconds = exMap['repos'] == null
            ? standardRest
            : _parseRestSeconds(exMap['repos']);
        final loadText = _parseLoadText(exMap);
        final isTimed = duration != null && duration > 0;
        exercises.add(
          ExerciseTemplate(
            id: 'ex_${dayOfWeek}_${exercises.length}',
            name: name,
            sets: sets,
            targetReps: repetitions == null ? '' : repetitions.toString(),
            targetWeight: 0,
            loadText: loadText,
            tempo: '',
            notes: '',
            restSeconds: restSeconds,
            isTimed: isTimed,
            durationSeconds: duration ?? 0,
          ),
        );
      }

      final sessionRest = exercises.isEmpty
          ? standardRest
          : _averageRestSeconds(exercises.map((e) => e.restSeconds).toList());

      sessions.add(
        WorkoutSessionTemplate(
          id: 'day_$dayOfWeek',
          name: title,
          exercises: exercises,
          restSeconds: sessionRest,
          estimatedDurationSeconds: estimatedDurationSeconds,
          order: i + 1,
          dayOfWeek: dayOfWeek,
        ),
      );
    }

    return ProgramImportData(
      program: WorkoutProgram(
        id: 'program',
        title: (json['titre'] as String?) ?? 'Programme',
        sessions: sessions,
        notes: notes,
      ),
      profile: profile,
    );
  }

  int _dayOfWeekFromLabel(String label) {
    final upper = label.toUpperCase();
    if (upper.startsWith('LUNDI')) return 1;
    if (upper.startsWith('MARDI')) return 2;
    if (upper.startsWith('MERCREDI')) return 3;
    if (upper.startsWith('JEUDI')) return 4;
    if (upper.startsWith('VENDREDI')) return 5;
    if (upper.startsWith('SAMEDI')) return 6;
    return 7;
  }

  int _parseRestSeconds(dynamic value) {
    if (value == null) return 90;
    if (value is num) return value.toInt();
    if (value is String) {
      final parts = value.replaceAll(' ', '').split('-');
      if (parts.length == 2) {
        final a = int.tryParse(parts[0]) ?? 60;
        final b = int.tryParse(parts[1]) ?? 60;
        return ((a + b) / 2).round();
      }
      return int.tryParse(value) ?? 90;
    }
    return 90;
  }

  String _parseLoadText(Map<String, dynamic> exMap) {
    if (exMap.containsKey('charge_par_main_kg')) {
      final value = exMap['charge_par_main_kg'];
      return '${value.toString()} kg/main';
    }
    if (exMap.containsKey('charge_totale_kg')) {
      final value = exMap['charge_totale_kg'];
      return '${value.toString()} kg total';
    }
    if (exMap.containsKey('charge')) {
      return exMap['charge'].toString();
    }
    return '';
  }

  int _averageRestSeconds(List<int> values) {
    if (values.isEmpty) return 90;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    return (total / values.length).round();
  }

  String _buildNotes(Map<String, dynamic>? meta) {
    if (meta == null) return '';
    final notes = <String>[];
    final regles = meta['regles_progression'] as List?;
    if (regles != null) {
      notes.addAll(regles.map((e) => e.toString()));
    }
    final other = meta['notes'] as List?;
    if (other != null) {
      notes.addAll(other.map((e) => e.toString()));
    }
    return notes.join('\n');
  }

  Profile? _parseProfile(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final height = (raw['taille_cm'] as num?)?.toInt() ?? 0;
    final weight = (raw['poids_kg'] as num?)?.toDouble() ?? 0;
    final goal = (raw['objectif'] as String?) ?? '';
    if (height == 0 && weight == 0 && goal.isEmpty) return null;
    return Profile(
      id: 'profile',
      name: '',
      heightCm: height,
      weightKg: weight,
      armLength: 'normal',
      femurLength: 'normal',
      limitations: <String>[],
      goal: goal.isEmpty ? 'hypertrophy' : goal,
      weightHistory: weight > 0
          ? [
              WeightEntry(
                dateIso: DateTime.now().toIso8601String(),
                weightKg: weight,
              ),
            ]
          : <WeightEntry>[],
    );
  }
}
