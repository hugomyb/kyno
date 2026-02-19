import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_state.dart';
import '../../models/program.dart';
import '../../models/session.dart';
import '../../providers/app_state_provider.dart';
import '../../services/audio_service.dart';
import '../../services/workout_ui_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/soft_card.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, this.sessionId, this.restart = false});

  final String? sessionId;
  final bool restart;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1F2937)),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

enum _WorkoutAction {
  skipStep,
  restart,
  nextExercise,
  prevSet,
  prevExercise,
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  WorkoutSessionTemplate? _template;
  WorkoutSession? _session;
  WorkoutSession? _completedSession;
  int _exerciseIndex = 0;
  int _setIndex = 0;
  int _restRemaining = 0;
  int _workRemaining = 0;
  int _countdownRemaining = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _elapsedTimer;
  DateTime? _startTime;
  DateTime? _lastPersist;
  bool _paused = false;
  bool _sessionFinished = false;
  bool _restartRequested = false;

  @override
  void initState() {
    super.initState();
    _tryRestoreActive();
    _restartRequested = widget.restart;
  }

  @override
  void dispose() {
    workoutActive.value = false;
    _timer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(appStateProvider).program;
    final state = ref.watch(appStateProvider);
    final active = workoutActive.value;

    if (_template == null && program.sessions.isNotEmpty) {
      if (widget.sessionId != null) {
        _template = program.sessions.firstWhere(
          (s) => s.id == widget.sessionId,
          orElse: () => program.sessions.first,
        );
      } else {
        final today = DateTime.now().weekday;
        _template = program.sessions.firstWhere(
          (s) => s.dayOfWeek == today,
          orElse: () => program.sessions.first,
        );
      }
    }
    if (_restartRequested && _template != null && _session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _restartRequested = false;
        ref.read(appStateProvider.notifier).clearActiveWorkout();
        ref.read(appStateProvider.notifier).save();
        _startSession(state);
      });
    }
    if (_session == null && active) {
      // no-op: avoid notifier writes during build
    }

    return Scaffold(
      backgroundColor: _session == null ? null : _backgroundColor(),
      body: Stack(
        children: [
          if (_session == null) const AppBackground(),
          SafeArea(
            child: program.sessions.isEmpty
                ? Center(
                    child: Text(
                      'Aucune seance disponible. Importer un programme.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : _completedSession != null
                    ? _summaryPanel()
                    : _session == null
                        ? _previewPanel(state)
                        : _focusPanel(),
          ),
        ],
      ),
    );
  }

  Widget _previewPanel(AppState state) {
    final session = _template;
    if (session == null) {
      return const SizedBox.shrink();
    }
    final estimateMinutes = _estimateSessionMinutes(session);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              session.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoChip('${session.exercises.length} exos'),
                const SizedBox(width: 8),
                _infoChip('${estimateMinutes.toStringAsFixed(0)} min'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: session.exercises.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final exercise = session.exercises[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        _indexBadge(index + 1),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _exerciseBadges(exercise),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: session.exercises.isEmpty
                    ? null
                    : () {
                        if (_resumeActiveIfAvailable(state)) {
                          return;
                        }
                        _startSession(state);
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasActiveForTemplate(state, session)
                          ? Icons.play_circle_fill
                          : Icons.play_arrow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(session.exercises.isEmpty
                        ? 'Repos'
                        : _hasActiveForTemplate(state, session)
                            ? 'Reprendre'
                            : 'Demarrer'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPanel() {
    final completed = _completedSession;
    if (completed == null) return const SizedBox.shrink();
    final totalExercises = completed.exerciseLogs.length;
    final duration = completed.durationMinutes;
    final date = completed.dateIso.isEmpty
        ? ''
        : _formatDateFr(DateTime.tryParse(completed.dateIso));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Seance terminee',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              completed.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip('$totalExercises exos'),
                _infoChip('$duration min'),
                if (date.isNotEmpty) _infoChip(date),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: completed.exerciseLogs.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final log = completed.exerciseLogs[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        _indexBadge(index + 1),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            log.exerciseName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _previewBadge(Icons.repeat, '${log.sets.length}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () {
                        if (mounted) context.go('/');
                      },
                      child: const Text('Accueil'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _restartFromSummary,
                      child: const Text('Recommencer'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDateFr(DateTime? date) {
    if (date == null) return '';
    const months = [
      'janvier',
      'fevrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'aout',
      'septembre',
      'octobre',
      'novembre',
      'decembre',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  void _tryRestoreActive() {
    final state = ref.read(appStateProvider);
    final active = state.activeWorkout;
    if (active == null) return;
    if (_isActiveInvalid(state, active)) {
      ref.read(appStateProvider.notifier).clearActiveWorkout();
      ref.read(appStateProvider.notifier).save();
      return;
    }
    if (widget.sessionId != null && active.session.templateId != widget.sessionId) {
      return;
    }
    final template = state.program.sessions.firstWhere(
      (s) => s.id == active.session.templateId,
      orElse: () => state.program.sessions.isNotEmpty
          ? state.program.sessions.first
          : WorkoutSessionTemplate(
              id: active.session.templateId,
              name: active.session.name,
              exercises: const [],
              restSeconds: 90,
              estimatedDurationSeconds: 0,
              order: 1,
              dayOfWeek: DateTime.now().weekday,
            ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _template = template;
        _session = active.session;
        _exerciseIndex = active.exerciseIndex;
        _setIndex = active.setIndex;
        _restRemaining = active.restRemaining;
        _workRemaining = active.workRemaining;
        _countdownRemaining = active.countdownRemaining;
        _elapsedSeconds = active.elapsedSeconds;
        _paused = active.paused;
        _startTime = active.startedAtIso.isEmpty
            ? DateTime.now()
            : DateTime.tryParse(active.startedAtIso);
        _sessionFinished = false;
      });
      workoutActive.value = true;
      _startElapsedTimer(keepValue: true);
      _resumeTimersFromState();
    });
  }

  bool _isActiveInvalid(AppState state, ActiveWorkout active) {
    if (state.sessions.any((s) => s.id == active.session.id)) {
      return true;
    }
    final today = DateTime.now();
    for (final session in state.sessions) {
      if (session.templateId != active.session.templateId) continue;
      if (session.dateIso.isEmpty) continue;
      final date = DateTime.tryParse(session.dateIso);
      if (date == null) continue;
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return true;
      }
    }
    return false;
  }

  void _resumeTimersFromState() {
    if (_countdownRemaining > 0) {
      _resumeCountdown(_countdownRemaining);
      return;
    }
    if (_workRemaining > 0) {
      _resumeWorkTimer(_workRemaining);
      return;
    }
    if (_restRemaining > 0) {
      _resumeRestTimer(_restRemaining);
    }
  }

  void _resumeWorkTimer(int remaining) {
    _timer?.cancel();
    setState(() => _workRemaining = remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      if (_workRemaining <= 1) {
        timer.cancel();
        setState(() => _workRemaining = 0);
        audioService.playBeep();
        _startRestTimer();
      } else {
        setState(() => _workRemaining -= 1);
        _persistActive(throttle: true);
      }
    });
  }

  void _resumeRestTimer(int remaining) {
    _timer?.cancel();
    setState(() => _restRemaining = remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      final next = _restRemaining - 1;
      setState(() => _restRemaining = next < 0 ? 0 : next);
      if (_restRemaining >= 1 && _restRemaining <= 3) {
        audioService.playBeep();
      }
      _persistActive(throttle: true);
      if (_restRemaining <= 0) {
        timer.cancel();
        _advance();
      }
    });
  }

  void _resumeCountdown(int remaining) {
    _timer?.cancel();
    setState(() => _countdownRemaining = remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      final next = _countdownRemaining - 1;
      setState(() => _countdownRemaining = next < 0 ? 0 : next);
      if (_countdownRemaining >= 1 && _countdownRemaining <= 3) {
        audioService.playBeep();
      }
      _persistActive(throttle: true);
      if (_countdownRemaining <= 0) {
        timer.cancel();
        _maybeStartTimedExercise();
      }
    });
  }

  bool _hasActiveForTemplate(AppState state, WorkoutSessionTemplate session) {
    return state.activeWorkout?.session.templateId == session.id;
  }

  bool _resumeActiveIfAvailable(AppState state) {
    if (!_hasActiveForTemplate(state, _template!)) return false;
    if (_session != null) return true;
    _tryRestoreActive();
    return true;
  }

  List<Widget> _exerciseBadges(ExerciseTemplate exercise) {
    final badges = <Widget>[
      _previewBadge(Icons.repeat, '${exercise.sets}'),
      if (exercise.isTimed)
        _previewBadge(Icons.timer_outlined, '${exercise.durationSeconds}s')
      else
        _previewBadge(Icons.fitness_center, '${exercise.targetReps}'),
      _previewBadge(Icons.snooze, '${exercise.restSeconds}s'),
    ];
    if (exercise.loadText.isNotEmpty) {
      badges.add(_previewBadge(Icons.scale_outlined, exercise.loadText));
    }
    return badges;
  }

  Widget _previewBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EDFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _indexBadge(int index) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF94A3B8),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        index.toString(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  double _estimateSessionMinutes(WorkoutSessionTemplate session) {
    return _estimateSessionSeconds(session) / 60.0;
  }

  int _estimateSessionSeconds(WorkoutSessionTemplate session) {
    if (session.estimatedDurationSeconds > 0) {
      return session.estimatedDurationSeconds;
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
      // 3 seconds per rep as a simple default cadence
      final work = reps * 3;
      totalSeconds += sets * (work + rest);
    }
    return totalSeconds.round();
  }

  int _estimateReps(String repsText) {
    final cleaned = repsText.replaceAll('–', '-').replaceAll('—', '-');
    final numbers = RegExp(r'\\d+').allMatches(cleaned).map((m) => int.parse(m.group(0)!)).toList();
    if (numbers.isEmpty) return 10;
    if (numbers.length == 1) return numbers.first;
    final avg = (numbers[0] + numbers[1]) / 2.0;
    return avg.round();
  }

  String _formatElapsed(int seconds) {
    final total = seconds.clamp(0, 24 * 3600);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final secs = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _focusPanel() {
    final templateExercise = _template?.exercises[_exerciseIndex];
    final isTimed = templateExercise?.isTimed ?? false;
    final target = isTimed
        ? '${templateExercise?.durationSeconds ?? 0}s'
        : '${templateExercise?.targetReps ?? ''} reps';
    final loadText = templateExercise?.loadText ?? '';
    final isResting = _restRemaining > 0;
    final isWorking = _workRemaining > 0;
    final timerLabel = isResting ? 'Repos' : 'Travail';
    final timerValue = isResting ? _restRemaining : _workRemaining;
    final showCountdown = _countdownRemaining > 0;
    final showTimer = (isResting || isWorking) && !showCountdown;
    final accent = isResting ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
    final elapsedLabel = _formatElapsed(_elapsedSeconds);
    final showNextExercise = isResting &&
        _setIndex == _currentExercise.sets.length - 1 &&
        _exerciseIndex + 1 < _session!.exerciseLogs.length;
    final nextExerciseName = showNextExercise
        ? _session!.exerciseLogs[_exerciseIndex + 1].exerciseName
        : '';
    final nextLoadText = showNextExercise
        ? (_template?.exercises[_exerciseIndex + 1].loadText ?? '')
        : '';
    final nextTarget = showNextExercise
        ? (() {
            final nextTemplate = _template?.exercises[_exerciseIndex + 1];
            if (nextTemplate == null) return '';
            if (nextTemplate.isTimed) {
              return '${nextTemplate.durationSeconds}s';
            }
            return '${nextTemplate.targetReps} reps';
          })()
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      elapsedLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: _quickActionsMenu(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SoftCard(
                color: backgroundColorLight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          timerLabel,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentExercise.exerciseName,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _infoPill(
                          icon: Icons.repeat,
                          label: '${_currentSet.setIndex}/${_currentExercise.sets.length}',
                        ),
                        _infoPill(
                          icon: isTimed ? Icons.timer_outlined : Icons.fitness_center,
                          label: isTimed ? '${templateExercise?.durationSeconds ?? 0}s' : target,
                        ),
                        if (loadText.isNotEmpty)
                          _infoPill(
                            icon: Icons.scale_outlined,
                            label: loadText,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (showCountdown) ...[
                      Text(
                        'Debut dans',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_countdownRemaining',
                        style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (showTimer)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '$timerValue s',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (showNextExercise) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fast_forward, size: 18, color: accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Prochain',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextExerciseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (nextTarget.isNotEmpty || nextLoadText.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (nextTarget.isNotEmpty)
                                    _infoPill(
                                      icon: Icons.fitness_center,
                                      label: nextTarget,
                                    ),
                                  if (nextLoadText.isNotEmpty)
                                    _infoPill(
                                      icon: Icons.scale_outlined,
                                      label: nextLoadText,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  if (!isTimed && !isResting && !showCountdown) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 64,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        onPressed: _paused ? null : _validateSet,
                        child: const Text('Valider serie', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ),
          Text(
            'Exercice ${_exerciseIndex + 1}/${_session!.exerciseLogs.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _togglePause,
                    child: Text(
                      _paused ? 'Reprendre' : 'Pause',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _stopSession,
                    child: const Text('Arreter', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionsMenu() {
    return PopupMenuButton<_WorkoutAction>(
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _WorkoutAction.skipStep,
          child: _MenuItem(
            icon: Icons.fast_forward_rounded,
            label: 'Passer serie / repos',
          ),
        ),
        PopupMenuItem(
          value: _WorkoutAction.prevSet,
          child: _MenuItem(
            icon: Icons.fast_rewind_rounded,
            label: 'Serie precedente',
          ),
        ),
        PopupMenuItem(
          value: _WorkoutAction.nextExercise,
          child: _MenuItem(
            icon: Icons.skip_next_rounded,
            label: 'Exercice suivant',
          ),
        ),
        PopupMenuItem(
          value: _WorkoutAction.prevExercise,
          child: _MenuItem(
            icon: Icons.skip_previous_rounded,
            label: 'Exercice precedent',
          ),
        ),
        PopupMenuItem(
          value: _WorkoutAction.restart,
          child: _MenuItem(
            icon: Icons.replay_rounded,
            label: 'Recommencer',
          ),
        ),
      ],
      onSelected: _handleQuickAction,
    );
  }

  void _handleQuickAction(_WorkoutAction action) {
    switch (action) {
      case _WorkoutAction.skipStep:
        _skipCurrentStep();
        break;
      case _WorkoutAction.restart:
        _confirmRestart();
        break;
      case _WorkoutAction.nextExercise:
        _jumpToExercise(_exerciseIndex + 1);
        break;
      case _WorkoutAction.prevSet:
        _jumpToSet(_setIndex - 1);
        break;
      case _WorkoutAction.prevExercise:
        _jumpToExercise(_exerciseIndex - 1);
        break;
    }
  }

  void _skipCurrentStep() {
    if (_session == null) return;
    if (_countdownRemaining > 0) {
      setState(() => _countdownRemaining = 0);
      _maybeStartTimedExercise();
      _persistActive(force: true);
      return;
    }
    if (_restRemaining > 0) {
      setState(() => _restRemaining = 0);
      _advance();
      return;
    }
    if (_workRemaining > 0) {
      setState(() => _workRemaining = 0);
      _startRestTimer();
      return;
    }
    if (!_currentExercise.sets.isEmpty) {
      _startRestTimer();
    }
  }

  void _jumpToExercise(int index) {
    if (_session == null) return;
    if (index < 0 || index >= _session!.exerciseLogs.length) return;
    _timer?.cancel();
    setState(() {
      _exerciseIndex = index;
      _setIndex = 0;
      _restRemaining = 0;
      _workRemaining = 0;
      _countdownRemaining = 0;
    });
    _maybeStartTimedExercise();
    _persistActive(force: true);
  }

  void _jumpToSet(int index) {
    if (_session == null) return;
    if (index < 0 || index >= _currentExercise.sets.length) return;
    _timer?.cancel();
    setState(() {
      _setIndex = index;
      _restRemaining = 0;
      _workRemaining = 0;
      _countdownRemaining = 0;
    });
    _maybeStartTimedExercise();
    _persistActive(force: true);
  }

  Future<void> _confirmRestart() async {
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
      _restartSession();
    }
  }

  void _restartSession() {
    if (_session == null || _template == null) return;
    _timer?.cancel();
    _elapsedTimer?.cancel();
    setState(() {
      _exerciseIndex = 0;
      _setIndex = 0;
      _restRemaining = 0;
      _workRemaining = 0;
      _countdownRemaining = 5;
      _elapsedSeconds = 0;
      _paused = false;
      _startTime = DateTime.now();
      _sessionFinished = false;
      _completedSession = null;
    });
    _startElapsedTimer();
    _persistActive(force: true);
    _startCountdown();
  }

  void _restartFromSummary() {
    final template = _template;
    if (template == null) return;
    setState(() {
      _completedSession = null;
    });
    _startSession(ref.read(appStateProvider));
  }

  void _startSession(AppState state) {
    if (_template == null) return;
    workoutActive.value = true;
    final notifier = ref.read(appStateProvider.notifier);
    final session = notifier.startSession(_template!);
    _prefillFromLast(state, session);

    setState(() {
      _session = session;
      _completedSession = null;
      _exerciseIndex = 0;
      _setIndex = 0;
      _restRemaining = 0;
      _workRemaining = 0;
      _countdownRemaining = 5;
      _paused = false;
      _startTime = DateTime.now();
      _sessionFinished = false;
    });
    _startElapsedTimer();
    _persistActive(force: true);
    _startCountdown();
  }

  void _prefillFromLast(AppState state, WorkoutSession session) {
    final previous = state.sessions
        .where((s) => s.templateId == session.templateId)
        .toList()
        .fold<WorkoutSession?>(
          null,
          (prev, element) => prev == null || element.dateIso.compareTo(prev.dateIso) > 0
              ? element
              : prev,
        );

    if (previous == null) return;

    final logs = session.exerciseLogs.map((exerciseLog) {
      final previousLog = previous.exerciseLogs.firstWhere(
        (log) => log.exerciseId == exerciseLog.exerciseId,
        orElse: () => exerciseLog,
      );
      return SessionExerciseLog(
        exerciseId: exerciseLog.exerciseId,
        exerciseName: exerciseLog.exerciseName,
        sets: List.generate(
          exerciseLog.sets.length,
          (index) {
            final prevSet = index < previousLog.sets.length
                ? previousLog.sets[index]
                : exerciseLog.sets[index];
            return SessionSetLog(
              setIndex: index + 1,
              reps: prevSet.reps,
              weight: prevSet.weight,
              rir: prevSet.rir,
            );
          },
        ),
      );
    }).toList();

    _session = session.copyWith(exerciseLogs: logs);
  }

  SessionExerciseLog get _currentExercise {
    return _session!.exerciseLogs[_exerciseIndex];
  }

  SessionSetLog get _currentSet {
    return _currentExercise.sets[_setIndex];
  }

  void _validateSet() {
    _startRestTimer();
  }

  void _startWorkTimer(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) {
      _startRestTimer();
      return;
    }
    setState(() => _workRemaining = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      if (_workRemaining <= 1) {
        timer.cancel();
        setState(() => _workRemaining = 0);
        audioService.playBeep();
        _startRestTimer();
      } else {
        setState(() => _workRemaining -= 1);
        _persistActive(throttle: true);
      }
    });
  }

  void _startRestTimer() {
    _timer?.cancel();
    if (_isLastSetOverall()) {
      _finishSession();
      return;
    }
    final rest = _calculateRestSeconds();
    if (rest <= 0) {
      _advance();
      return;
    }
    setState(() => _restRemaining = rest);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      final next = _restRemaining - 1;
      setState(() => _restRemaining = next < 0 ? 0 : next);
      if (_restRemaining >= 1 && _restRemaining <= 3) {
        audioService.playBeep();
      }
      _persistActive(throttle: true);
      if (_restRemaining <= 0) {
        timer.cancel();
        _advance();
      }
    });
  }

  void _advance() {
    if (_session == null) return;
    if (_setIndex + 1 < _currentExercise.sets.length) {
      setState(() => _setIndex += 1);
      _persistActive(force: true);
      _maybeStartTimedExercise();
      return;
    }
    if (_exerciseIndex + 1 < _session!.exerciseLogs.length) {
      setState(() {
        _exerciseIndex += 1;
        _setIndex = 0;
      });
      _persistActive(force: true);
      _maybeStartTimedExercise();
      return;
    }
    _finishSession();
  }

  bool _isLastSetOverall() {
    if (_session == null) return false;
    if (_exerciseIndex != _session!.exerciseLogs.length - 1) return false;
    if (_setIndex != _currentExercise.sets.length - 1) return false;
    return true;
  }

  void _finishSession() {
    if (_sessionFinished) return;
    _sessionFinished = true;
    final notifier = ref.read(appStateProvider.notifier);
    final durationMinutes = _startTime == null
        ? 0
        : DateTime.now().difference(_startTime!).inMinutes;

    _timer?.cancel();
    _elapsedTimer?.cancel();

    final completed = _session!.copyWith(
      dateIso: DateTime.now().toIso8601String(),
      durationMinutes: durationMinutes,
    );
    notifier.addSession(completed);
    notifier.clearActiveWorkout();
    notifier.save();
    workoutActive.value = false;

    if (!mounted) return;
    setState(() {
      _completedSession = completed;
      _session = null;
    });
  }

  int _calculateRestSeconds() {
    final base =
        _template?.exercises[_exerciseIndex].restSeconds ?? _template?.restSeconds ?? 90;
    return base.clamp(30, 600);
  }

  void _maybeStartTimedExercise() {
    final templateExercise = _template?.exercises[_exerciseIndex];
    if (templateExercise == null) return;
    if (!templateExercise.isTimed) return;
    _startWorkTimer(templateExercise.durationSeconds);
  }

  void _startElapsedTimer({bool keepValue = false}) {
    _elapsedTimer?.cancel();
    if (!keepValue) {
      _elapsedSeconds = 0;
    }
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      setState(() => _elapsedSeconds += 1);
      _persistActive(throttle: true);
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_countdownRemaining <= 0) {
      _countdownRemaining = 0;
      _maybeStartTimedExercise();
      return;
    }
    audioService.playBeep();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      final next = _countdownRemaining - 1;
      setState(() => _countdownRemaining = next < 0 ? 0 : next);
      if (_countdownRemaining >= 1 && _countdownRemaining <= 3) {
        audioService.playBeep();
      }
      _persistActive(throttle: true);
      if (_countdownRemaining <= 0) {
        timer.cancel();
        _maybeStartTimedExercise();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
    _persistActive(force: true);
  }

  Future<void> _stopSession() async {
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
                  'Arreter la seance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirmer l arret de la seance ?',
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
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Arreter', style: TextStyle(fontSize: 18)),
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
    if (result != true) return;
    _sessionFinished = true;
    _timer?.cancel();
    _elapsedTimer?.cancel();
    workoutActive.value = false;
    ref.read(appStateProvider.notifier).clearActiveWorkout();
    ref.read(appStateProvider.notifier).save();
    if (mounted) {
      context.go('/');
    }
  }

  void _persistActive({bool force = false, bool throttle = false}) {
    if (!mounted) return;
    if (_session == null) return;
    if (_sessionFinished) return;
    final now = DateTime.now();
    if (throttle && !force) {
      final last = _lastPersist;
      if (last != null && now.difference(last).inSeconds < 5) {
        return;
      }
    }
    _lastPersist = now;
    final notifier = ref.read(appStateProvider.notifier);
    notifier.setActiveWorkout(
      ActiveWorkout(
        session: _session!,
        exerciseIndex: _exerciseIndex,
        setIndex: _setIndex,
        restRemaining: _restRemaining,
        workRemaining: _workRemaining,
        countdownRemaining: _countdownRemaining,
        elapsedSeconds: _elapsedSeconds,
        startedAtIso: _startTime?.toIso8601String() ?? '',
        paused: _paused,
      ),
    );
    notifier.save();
  }

  Color _backgroundColor() {
    return backgroundColor2;
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EDFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
