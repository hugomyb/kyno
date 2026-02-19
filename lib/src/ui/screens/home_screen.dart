import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_state.dart';
import '../../models/program.dart';
import '../../models/session.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/soft_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final program = state.program;
    final todaySession = _findTodaySession(program.sessions);
    final activeWorkout = state.activeWorkout;
    final latestCompleted = _latestCompletedSession(state);
    final hasCompletedForActiveToday =
        activeWorkout != null && _isCompletedToday(ref, activeWorkout.session.templateId);
    final isActiveStale =
        hasCompletedForActiveToday || _isActiveStale(state, activeWorkout, latestCompleted);
    if (isActiveStale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(appStateProvider.notifier).clearActiveWorkout();
        ref.read(appStateProvider.notifier).save();
      });
    }
    final effectiveActive = isActiveStale ? null : activeWorkout;
    final completedForToday = todaySession == null
        ? null
        : _latestCompletedForToday(state, todaySession.id);

    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (latestCompleted != null &&
                    _isCompletedToday(ref, latestCompleted.templateId) &&
                    (todaySession == null ||
                        latestCompleted.templateId != todaySession.id))
                  ...[
                    _completedCard(context, latestCompleted),
                    const SizedBox(height: 16),
                  ],
                if (effectiveActive != null) ...[
                  _activeCard(context, effectiveActive),
                  const SizedBox(height: 16),
                ],
                if (todaySession == null ||
                    effectiveActive?.session.templateId != todaySession.id)
                  _todayCard(context, ref, todaySession),
                const SizedBox(height: 16),
                if (program.sessions.isNotEmpty)
                  _otherSessionsCard(context, program.sessions, todaySession),
                if (program.sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: FilledButton(
                      onPressed: () => context.go('/import'),
                      child: const Text('Importer un programme'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  WorkoutSessionTemplate? _findTodaySession(List<WorkoutSessionTemplate> sessions) {
    if (sessions.isEmpty) return null;
    final today = DateTime.now().weekday;
    return sessions.firstWhere(
      (s) => s.dayOfWeek == today,
      orElse: () => sessions.first,
    );
  }

  Widget _todayCard(BuildContext context, WidgetRef ref, WorkoutSessionTemplate? session) {
    if (session == null) {
      return const SizedBox.shrink();
    }

    final isRestDay = session.exercises.isEmpty;
    final completedToday = _isCompletedToday(ref, session.id);
    final estimatedMinutes = _estimateSessionMinutes(session);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seance du jour',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            session.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('${session.exercises.length} exos'),
              const SizedBox(width: 8),
              _chip('${estimatedMinutes.toStringAsFixed(0)} min'),
              if (completedToday) ...[
                const SizedBox(width: 8),
                _chip('Terminee', color: const Color(0xFF16A34A)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(
              onPressed: isRestDay
                  ? null
                  : () => context.go('/workout?sessionId=${session.id}'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    completedToday ? Icons.restart_alt : Icons.play_arrow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(isRestDay
                      ? 'Repos'
                      : completedToday
                          ? 'Recommencer'
                          : 'Demarrer'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeCard(BuildContext context, ActiveWorkout activeWorkout) {
    final sessionName = activeWorkout.session.name;
    final label = activeWorkout.paused ? 'En pause' : 'En cours';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seance en cours',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip(label),
              const SizedBox(width: 8),
              _chip('Exo ${activeWorkout.exerciseIndex + 1}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () =>
                        context.go('/workout?sessionId=${activeWorkout.session.templateId}'),
                    child: const Text('Reprendre'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _confirmRestart(context, activeWorkout.session.templateId),
                    child: const Text('Recommencer'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context, String sessionTemplateId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Recommencer la seance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tout le progres actuel sera perdu.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Annuler', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Recommencer', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == true) {
      context.go('/workout?sessionId=$sessionTemplateId&restart=1');
    }
  }

  Widget _completedCard(BuildContext context, WorkoutSession session) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seance terminee',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            session.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('${session.exerciseLogs.length} exos'),
              const SizedBox(width: 8),
              _chip('${session.durationMinutes} min'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/workout?sessionId=${session.templateId}&restart=1'),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restart_alt, size: 20),
                  SizedBox(width: 8),
                  Text('Recommencer'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCompletedToday(WidgetRef ref, String templateId) {
    final sessions = ref.read(appStateProvider).sessions;
    final today = DateTime.now();
    for (final session in sessions) {
      if (session.templateId != templateId) continue;
      if (session.dateIso.isEmpty) continue;
      final date = DateTime.tryParse(session.dateIso);
      if (date == null) continue;
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return true;
      }
    }
    return false;
  }

  WorkoutSession? _latestCompletedSession(AppState state) {
    WorkoutSession? latest;
    for (final session in state.sessions) {
      if (session.dateIso.isEmpty) continue;
      final date = DateTime.tryParse(session.dateIso);
      if (date == null) continue;
      if (latest == null) {
        latest = session;
      } else {
        final latestDate = DateTime.tryParse(latest.dateIso);
        if (latestDate == null || date.isAfter(latestDate)) {
          latest = session;
        }
      }
    }
    return latest;
  }

  WorkoutSession? _latestCompletedForToday(AppState state, String templateId) {
    final today = DateTime.now();
    WorkoutSession? latest;
    for (final session in state.sessions) {
      if (session.templateId != templateId) continue;
      if (session.dateIso.isEmpty) continue;
      final date = DateTime.tryParse(session.dateIso);
      if (date == null) continue;
      if (date.year != today.year || date.month != today.month || date.day != today.day) {
        continue;
      }
      if (latest == null) {
        latest = session;
      } else {
        final latestDate = DateTime.tryParse(latest.dateIso);
        if (latestDate == null || date.isAfter(latestDate)) {
          latest = session;
        }
      }
    }
    return latest;
  }

  bool _isActiveStale(
    AppState state,
    ActiveWorkout? activeWorkout,
    WorkoutSession? latestCompleted,
  ) {
    if (activeWorkout == null) return false;
    if (state.sessions.any((session) => session.id == activeWorkout.session.id)) {
      return true;
    }
    if (latestCompleted == null) return false;
    if (latestCompleted.templateId != activeWorkout.session.templateId) return false;
    final activeStart = DateTime.tryParse(activeWorkout.startedAtIso);
    final completedAt = DateTime.tryParse(latestCompleted.dateIso);
    if (activeStart == null || completedAt == null) return false;
    return completedAt.isAfter(activeStart) || completedAt.isAtSameMomentAs(activeStart);
  }

  Widget _otherSessionsCard(
    BuildContext context,
    List<WorkoutSessionTemplate> sessions,
    WorkoutSessionTemplate? todaySession,
  ) {
    final otherSessions =
        sessions.where((session) => session.id != todaySession?.id).toList();
    if (otherSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir une autre seance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final session in otherSessions)
            ListTile(
              title: Text(session.name),
              subtitle: Text('${session.exercises.length} exercices'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/workout?sessionId=${session.id}'),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE6EDFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color == null ? null : Colors.white,
        ),
      ),
    );
  }

  double _estimateSessionMinutes(WorkoutSessionTemplate session) {
    if (session.estimatedDurationSeconds > 0) {
      return session.estimatedDurationSeconds / 60.0;
    }
    var totalSeconds = 0.0;
    for (final exercise in session.exercises) {
      final rest = exercise.restSeconds;
      final sets = exercise.sets;
      if (exercise.isTimed) {
        totalSeconds += sets * (exercise.durationSeconds + rest);
        continue;
      }
      final reps = _estimateReps(exercise.targetReps);
      final work = reps * 3;
      totalSeconds += sets * (work + rest);
    }
    return totalSeconds / 60.0;
  }

  int _estimateReps(String repsText) {
    final cleaned = repsText.replaceAll('–', '-').replaceAll('—', '-');
    final numbers = RegExp(r'\\d+')
        .allMatches(cleaned)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (numbers.isEmpty) return 10;
    if (numbers.length == 1) return numbers.first;
    final avg = (numbers[0] + numbers[1]) / 2.0;
    return avg.round();
  }
}
