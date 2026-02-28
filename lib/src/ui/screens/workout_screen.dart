import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/session.dart';
import '../../models/session_template.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../../services/workout_resume_state.dart';
import '../../services/workout_ui_state.dart';
import '../../utils/number_format.dart';
import '../theme/app_colors.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/soft_card.dart';

enum WorkoutStage { recap, countdown, running, summary }

enum WorkoutStepType { exercise, rest }

class WorkoutStep {
  WorkoutStep({
    required this.type,
    required this.title,
    required this.durationSeconds,
    this.isCircuitExercise = false,
    this.exercise,
    this.subtitle,
    this.round,
    this.totalRounds,
    this.setIndex,
    this.totalSets,
    this.circuitIndex,
    this.circuitTotal,
  });

  final WorkoutStepType type;
  final String title;
  final int durationSeconds;
  final SessionExerciseConfig? exercise;
  final String? subtitle;
  final int? round;
  final int? totalRounds;
  final int? setIndex;
  final int? totalSets;
  final bool isCircuitExercise;
  final int? circuitIndex;
  final int? circuitTotal;

  bool get isTimedExercise => type == WorkoutStepType.exercise && durationSeconds > 0;
}

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    this.sessionId,
    this.restart = false,
    this.resumeRequested = false,
  });

  final String? sessionId;
  final bool restart;
  final bool resumeRequested;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _uuid = const Uuid();
  Timer? _timer;
  Timer? _elapsedTimer;
  WorkoutStage _stage = WorkoutStage.recap;
  List<WorkoutStep> _steps = [];
  int _currentStepIndex = 0;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  bool _paused = false;
  bool _soundEnabled = true;
  bool _sessionReady = false;
  bool _soundInitialized = false;
  bool _audioUnlocked = false;
  bool _wakeLockHeld = false;
  bool _pendingStateHydrated = false;
  WorkoutSessionLog? _completedSession;
  Map<String, String> _lastPerformanceByExerciseId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      workoutActive.value = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    _setSessionAwake(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      workoutActive.value = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appDataProvider);
    final session = state.sessions.firstWhere(
      (s) => s.id == widget.sessionId,
      orElse: () => TrainingSessionTemplate(
        id: '',
        name: 'Séance',
        notes: null,
        groups: const [],
      ),
    );

    if (session.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Séance introuvable.')));
    }

    if (!_soundInitialized && state.profile.id != 'profile') {
      _soundEnabled = state.profile.soundEnabled;
      _soundInitialized = true;
    }

    if (!_sessionReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _prepareSession(session);
      });
    }

    return Scaffold(
      backgroundColor: _stage == WorkoutStage.running ? backgroundColor2 : null,
      body: Stack(
        children: [
          if (_stage != WorkoutStage.running) const AppBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildStage(context, session),
            ),
          ),
          if (_stage == WorkoutStage.recap)
            Positioned(
              left: 20,
              top: 20,
              child: SafeArea(
                child: IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          if (_stage == WorkoutStage.running)
            Positioned(
              left: 20,
              top: 20,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => _openSessionOverview(session),
                  icon: const Icon(Icons.list_alt),
                ),
              ),
            ),
          Positioned(
            right: 20,
            top: 20,
            child: SafeArea(
              child: IconButton(
                onPressed: _toggleSound,
                icon: Icon(
                  _soundEnabled ? Icons.volume_up : Icons.volume_off,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context, TrainingSessionTemplate session) {
    switch (_stage) {
      case WorkoutStage.recap:
        return _recapView(session);
      case WorkoutStage.countdown:
        return _countdownView();
      case WorkoutStage.running:
        return _runningView(session);
      case WorkoutStage.summary:
        return _summaryView();
    }
  }

  Widget _recapView(TrainingSessionTemplate session) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;

        return Center(
          key: const ValueKey('recap'),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        session.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _infoChip('${session.groups.length} blocs'),
                      const SizedBox(width: 8),
                      _infoChip('${_steps.length} étapes'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < session.groups.length; i++) ...[
                    _groupCard(session.groups[i], i),
                    if (i != session.groups.length - 1) const Divider(height: 18),
                  ],
                ],
              ),
            ),
          ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _startFromRecap,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_arrow, size: 20),
                              SizedBox(width: 8),
                              Text('Démarrer'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _countdownView() {
    final firstExercise = _steps.firstWhere(
      (step) => step.type == WorkoutStepType.exercise,
      orElse: () => WorkoutStep(
        type: WorkoutStepType.exercise,
        title: 'Exercice',
        durationSeconds: 0,
      ),
    );
    final isCircuit = firstExercise.isCircuitExercise;

    return Builder(
      builder: (context) {
        final colors = context.themeColors;
        final accent = colors.primary;

        return Center(
          key: const ValueKey('countdown'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.chipBackground(colors.primary),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'Début de séance',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SoftCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.chipBackground(accent),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Prêt ?',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            firstExercise.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      const SizedBox(height: 14),
                      if (firstExercise.subtitle != null) ...[
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (isCircuit && firstExercise.round != null && firstExercise.totalRounds != null)
                              _infoPill(
                                icon: Icons.autorenew,
                                label: 'Tour ${firstExercise.round}/${firstExercise.totalRounds}',
                              ),
                            if (isCircuit &&
                                firstExercise.circuitIndex != null &&
                                firstExercise.circuitTotal != null)
                              _infoPill(
                                icon: Icons.format_list_numbered,
                                label:
                                    'Exercice ${firstExercise.circuitIndex}/${firstExercise.circuitTotal}',
                              ),
                            _infoPill(
                              icon: firstExercise.isTimedExercise
                                  ? Icons.timer_outlined
                                  : Icons.fitness_center,
                              label: firstExercise.subtitle!,
                            ),
                          ],
                        ),
                      ] else if (isCircuit &&
                          firstExercise.round != null &&
                          firstExercise.totalRounds != null) ...[
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _infoPill(
                              icon: Icons.autorenew,
                              label: 'Tour ${firstExercise.round}/${firstExercise.totalRounds}',
                            ),
                            if (firstExercise.circuitIndex != null &&
                                firstExercise.circuitTotal != null)
                              _infoPill(
                                icon: Icons.format_list_numbered,
                                label:
                                    'Exercice ${firstExercise.circuitIndex}/${firstExercise.circuitTotal}',
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.chipBackground(accent),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '$_remainingSeconds s',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _summaryView() {
    final completed = _completedSession;
    if (completed == null) {
      return const SizedBox.shrink();
    }
    final state = ref.read(appDataProvider);
    final template = state.sessions.firstWhere(
      (s) => s.id == completed.sessionId,
      orElse: () => TrainingSessionTemplate(
        id: '',
        name: completed.name,
        notes: null,
        groups: const [],
      ),
    );
    final totalExercises = completed.exerciseLogs.length;
    final duration = completed.durationMinutes;
    return Builder(
      builder: (context) {
        final colors = context.themeColors;

        return Center(
          key: const ValueKey('summary'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Séance terminée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    completed.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoChip('$totalExercises exos'),
                  _infoChip('$duration min'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < template.groups.length; i++) ...[
                      _summaryGroup(template.groups[i], i + 1, completed),
                      const Divider(height: 24),
                    ],
                    if (template.groups.isEmpty)
                      for (var i = 0; i < completed.exerciseLogs.length; i++)
                        _summaryExerciseRow(completed.exerciseLogs[i], i + 1),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => context.go('/'),
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
      ),
        );
      },
    );
  }

  Widget _runningView(TrainingSessionTemplate session) {
    final step = _steps[_currentStepIndex];
    final isRest = step.type == WorkoutStepType.rest;
    final isTimed = step.isTimedExercise || isRest;
    final nextExercise = _nextExerciseStep();
    final nextCircuitSteps = nextExercise != null && nextExercise.isCircuitExercise
        ? _collectCircuitRoundSteps(_currentStepIndex + 1)
        : const <WorkoutStep>[];
    final nextCircuitExercise = _nextCircuitExercise(step);
    final restExerciseName = isRest ? _previousExerciseName() : null;
    final isCircuitExercise = step.isCircuitExercise;
    final showNextExercise = isRest &&
        step.type == WorkoutStepType.rest &&
        ((step.setIndex != null &&
                step.totalSets != null &&
                step.setIndex == step.totalSets) ||
            (step.round != null && step.totalRounds != null && step.round == step.totalRounds));

    return Builder(
      builder: (context) {
        final colors = context.themeColors;
        final accent = isRest
            ? (colors.isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B))
            : colors.primary;

        return Padding(
          key: const ValueKey('running'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _formatElapsed(_elapsedSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
            ),
          ),
          Expanded(
            child: Center(
              child: SoftCard(
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
                          isRest
                              ? 'Repos'
                              : (step.isCircuitExercise ? 'Circuit' : 'Exercice'),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRest ? (restExerciseName ?? step.title) : step.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (step.round != null && step.totalRounds != null)
                          _infoPill(
                            icon: Icons.autorenew,
                            label: 'Tour ${step.round}/${step.totalRounds}',
                          ),
                        if (isCircuitExercise &&
                            step.circuitIndex != null &&
                            step.circuitTotal != null)
                          _infoPill(
                            icon: Icons.format_list_numbered,
                            label: 'Exercice ${step.circuitIndex}/${step.circuitTotal}',
                          ),
                        if (!isCircuitExercise && step.setIndex != null && step.totalSets != null)
                          _infoPill(
                            icon: Icons.repeat,
                            label: 'Série ${step.setIndex}/${step.totalSets}',
                          ),
                        if (step.subtitle != null)
                          _infoPill(
                            icon: step.isTimedExercise ? Icons.timer_outlined : Icons.fitness_center,
                            label: step.subtitle!,
                          ),
                      ],
                    ),
                    if (!isRest && step.exercise != null) ...[
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    if (isTimed)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${_remainingSeconds}s',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (nextExercise != null && showNextExercise) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.cardBackgroundAlt,
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
                              (!step.isCircuitExercise && nextExercise.isCircuitExercise)
                                  ? 'Circuit'
                                  : nextExercise.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!step.isCircuitExercise &&
                                nextExercise.isCircuitExercise &&
                                nextCircuitSteps.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Column(
                                children: [
                                  for (final circuitStep in nextCircuitSteps)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            circuitStep.title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (circuitStep.subtitle != null) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                _infoPill(
                                                  icon: circuitStep.isTimedExercise
                                                      ? Icons.timer_outlined
                                                      : Icons.fitness_center,
                                                  label: circuitStep.subtitle!,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ] else if (nextExercise.subtitle != null) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (nextExercise.isCircuitExercise &&
                                      nextExercise.round != null &&
                                      nextExercise.totalRounds != null)
                                    _infoPill(
                                      icon: Icons.autorenew,
                                      label:
                                          'Tour ${nextExercise.round}/${nextExercise.totalRounds}',
                                    ),
                                  if (nextExercise.isCircuitExercise &&
                                      nextExercise.circuitIndex != null &&
                                      nextExercise.circuitTotal != null)
                                    _infoPill(
                                      icon: Icons.format_list_numbered,
                                      label:
                                          'Exercice ${nextExercise.circuitIndex}/${nextExercise.circuitTotal}',
                                    ),
                                  _infoPill(
                                    icon: Icons.fitness_center,
                                    label: nextExercise.subtitle!,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (step.type == WorkoutStepType.exercise && !step.isTimedExercise) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 64,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: _paused ? null : _advanceStep,
                          child: Text(
                            isCircuitExercise ? 'Valider l’exercice' : 'Valider la série',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                    if (nextCircuitExercise != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.cardBackgroundAlt,
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
                                Icon(Icons.skip_next, size: 18, color: accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Exercice suivant',
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
                              nextCircuitExercise.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (nextCircuitExercise.subtitle != null) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (nextCircuitExercise.circuitIndex != null &&
                                      nextCircuitExercise.circuitTotal != null)
                                    _infoPill(
                                      icon: Icons.format_list_numbered,
                                      label:
                                          'Exercice ${nextCircuitExercise.circuitIndex}/${nextCircuitExercise.circuitTotal}',
                                    ),
                                  _infoPill(
                                    icon: nextCircuitExercise.isTimedExercise
                                        ? Icons.timer_outlined
                                        : Icons.fitness_center,
                                    label: nextCircuitExercise.subtitle!,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Text(
            'Étape ${_currentStepIndex + 1}/${_steps.length}',
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
                    child: const Text('Arrêter', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _groupCard(SessionGroup group, int index) {
    final isCircuit = group.exercises.length > 1;
    return Builder(
      builder: (context) {
        final colors = context.themeColors;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCircuit
                  ? 'Circuit ${index + 1} · ${group.rounds} ${group.rounds == 1 ? 'tour' : 'tours'}'
                  : 'Exercice ${index + 1} · ${group.rounds} ${group.rounds == 1 ? 'série' : 'séries'}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final exercise in group.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _exerciseLabel(exercise),
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _recapExerciseBadges(exercise),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _exerciseLabel(SessionExerciseConfig exercise) {
    final target =
        exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps';
    final load = exercise.loadType == 'bodyweight'
        ? 'PDC'
        : '${formatDecimalFr(exercise.loadValue)}kg (${exercise.loadMode == 'per_hand' ? 'par main' : 'total'})';
    return '${exercise.exercise?.name ?? 'Exercice'} · $target · $load';
  }

  List<Widget> _recapExerciseBadges(SessionExerciseConfig exercise) {
    final target =
        exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps';
    final load = exercise.loadType == 'bodyweight'
        ? 'PDC'
        : '${formatDecimalFr(exercise.loadValue)}kg (${exercise.loadMode == 'per_hand' ? 'par main' : 'total'})';

    final badges = <Widget>[
      _infoPill(
        icon: exercise.isTimed ? Icons.timer_outlined : Icons.fitness_center,
        label: target,
      ),
      _infoPill(icon: Icons.scale_outlined, label: load),
    ];

    final lastPerf = _lastPerformanceByExerciseId[exercise.exerciseId];
    if (lastPerf != null) {
      badges.add(_lastPerformancePill(lastPerf));
    }

    return badges;
  }

  Widget _lastPerformancePill(String performance) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;
        final warningColor = colors.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        final warningBg = colors.isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: warningBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 17, color: warningColor),
              const SizedBox(width: 7),
              Text(
                'Dernier: $performance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: warningColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(String label) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.chipBackground(colors.primary),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        );
      },
    );
  }

  Widget _indexBadge(int index) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.border,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            index.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _summaryGroup(SessionGroup group, int index, WorkoutSessionLog completed) {
    final isCircuit = group.exercises.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCircuit
              ? 'Circuit $index · ${group.rounds} ${group.rounds == 1 ? 'tour' : 'tours'}'
              : 'Exercice $index · ${group.rounds} ${group.rounds == 1 ? 'série' : 'séries'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final exercise in group.exercises)
          _summaryExerciseRow(
            _findLog(
              completed,
              exercise.exerciseId,
              exerciseName: exercise.exercise?.name,
            ),
            null,
            fallbackName: exercise.exercise?.name ?? 'Exercice',
            template: exercise,
          ),
      ],
    );
  }

  WorkoutExerciseLog? _findLog(WorkoutSessionLog completed, String exerciseId,
      {String? exerciseName}) {
    for (final log in completed.exerciseLogs) {
      if (log.exerciseId == exerciseId) return log;
    }
    if (exerciseName != null && exerciseName.isNotEmpty) {
      for (final log in completed.exerciseLogs) {
        if (log.exerciseName == exerciseName) return log;
      }
    }
    return null;
  }

  Widget _summaryExerciseRow(
    WorkoutExerciseLog? log,
    int? index, {
    String? fallbackName,
    SessionExerciseConfig? template,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;

        if (log == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fallbackName ?? 'Exercice',
                  style: TextStyle(color: colors.textSecondary),
                ),
            if (template != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoPill(
                    icon: template.isTimed ? Icons.timer_outlined : Icons.fitness_center,
                    label: template.isTimed
                        ? '${template.targetSeconds}s'
                        : '${template.targetReps} reps',
                  ),
                  _infoPill(
                    icon: Icons.scale_outlined,
                    label: template.loadType == 'bodyweight'
                        ? 'PDC'
                        : '${formatDecimalFr(template.loadValue)}kg (${template.loadMode == 'per_hand' ? 'par main' : 'total'})',
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }
    final target = template == null
        ? null
        : (template.isTimed ? '${template.targetSeconds}s' : '${template.targetReps} reps');
    final load = template == null
        ? null
        : (template.loadType == 'bodyweight'
            ? 'PDC'
            : '${formatDecimalFr(template.loadValue)}kg (${template.loadMode == 'per_hand' ? 'par main' : 'total'})');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (index != null) ...[
            _indexBadge(index),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.exerciseName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoPill(icon: Icons.repeat, label: '${log.sets.length} séries'),
                    if (target != null)
                      _infoPill(
                        icon: template?.isTimed == true
                            ? Icons.timer_outlined
                            : Icons.fitness_center,
                        label: target,
                      ),
                    if (load != null)
                      _infoPill(icon: Icons.scale_outlined, label: load),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: colors.chipBackground(colors.primary),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: colors.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _prepareSession(TrainingSessionTemplate session) {
    _steps = _buildSteps(session);
    _currentStepIndex = 0;
    _remainingSeconds = 0;
    _stage = WorkoutStage.recap;
    _elapsedSeconds = 0;
    _paused = false;
    _sessionReady = true;
    _lastPerformanceByExerciseId = _buildLastPerformanceMap();

    if (widget.resumeRequested && !_pendingStateHydrated) {
      _pendingStateHydrated = true;
      _restorePendingState(session);
    }

    setState(() {});
  }

  void _restorePendingState(TrainingSessionTemplate session) {
    if (_steps.isEmpty) {
      return;
    }

    final storage = ref.read(storageProvider);
    final raw = storage.getString(StorageService.pendingWorkoutKey);
    final pending = raw == null ? null : PendingWorkoutState.fromStorageString(raw);

    if (pending == null || pending.sessionId != session.id) {
      return;
    }

    _currentStepIndex = pending.currentStepIndex.clamp(0, _steps.length - 1);
    _remainingSeconds = pending.remainingSeconds < 0 ? 0 : pending.remainingSeconds;
    _elapsedSeconds = pending.elapsedSeconds < 0 ? 0 : pending.elapsedSeconds;
    _paused = pending.paused;
    _completedSession = null;

    if (pending.stage == PendingWorkoutStage.countdown) {
      _stage = WorkoutStage.countdown;
      _startCountdownTimer(preserveRemaining: true);
    } else {
      _stage = WorkoutStage.running;
      _startElapsedTimer();
      _startStep(preserveRemaining: true);
    }
  }

  Map<String, String> _buildLastPerformanceMap() {
    final workoutSessions = ref.read(appDataProvider).workoutSessions;
    final sorted = [...workoutSessions]
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    final map = <String, String>{};

    for (final session in sorted) {
      for (final log in session.exerciseLogs) {
        final exerciseId = log.exerciseId;
        if (exerciseId == null || map.containsKey(exerciseId)) continue;
        if (log.sets.isEmpty) continue;
        final bestSet = log.sets.reduce((a, b) => a.weight > b.weight ? a : b);
        if (bestSet.weight > 0) {
          map[exerciseId] = '${formatDecimalFr(bestSet.weight)}kg × ${bestSet.reps}';
        } else if (bestSet.reps > 0) {
          map[exerciseId] = '${bestSet.reps} reps';
        }
      }
    }

    return map;
  }

  List<WorkoutStep> _buildSteps(TrainingSessionTemplate session) {
    final steps = <WorkoutStep>[];
    for (final group in session.groups) {
      final isCircuit = group.exercises.length > 1;
      for (var round = 1; round <= group.rounds; round++) {
        if (isCircuit) {
          for (var i = 0; i < group.exercises.length; i++) {
            final exercise = group.exercises[i];
            final name = exercise.exercise?.name ?? 'Exercice';
            final target =
                exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps';
            final load = exercise.loadType == 'bodyweight'
                ? 'PDC'
                : '${formatDecimalFr(exercise.loadValue)}kg (${exercise.loadMode == 'per_hand' ? 'par main' : 'total'})';
            steps.add(
              WorkoutStep(
                type: WorkoutStepType.exercise,
                title: name,
                subtitle: '$target · $load',
                durationSeconds: exercise.isTimed ? exercise.targetSeconds : 0,
                exercise: exercise,
                round: round,
                totalRounds: group.rounds,
                isCircuitExercise: true,
                circuitIndex: i + 1,
                circuitTotal: group.exercises.length,
              ),
            );
          }
        } else {
          for (final exercise in group.exercises) {
            final name = exercise.exercise?.name ?? 'Exercice';
            final target =
                exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps';
            final load = exercise.loadType == 'bodyweight'
                ? 'PDC'
                : '${formatDecimalFr(exercise.loadValue)}kg (${exercise.loadMode == 'per_hand' ? 'par main' : 'total'})';
            steps.add(
              WorkoutStep(
                type: WorkoutStepType.exercise,
                title: name,
                subtitle: '$target · $load',
                durationSeconds: exercise.isTimed ? exercise.targetSeconds : 0,
                exercise: exercise,
                setIndex: round,
                totalSets: group.rounds,
              ),
            );
          }
        }
        final hasRest = group.restBetweenRoundsSeconds > 0;
        if (hasRest) {
          steps.add(
            WorkoutStep(
              type: WorkoutStepType.rest,
              title: 'Repos',
              durationSeconds: group.restBetweenRoundsSeconds,
              round: isCircuit ? round : null,
              totalRounds: isCircuit ? group.rounds : null,
              setIndex: isCircuit ? null : round,
              totalSets: isCircuit ? null : group.rounds,
            ),
          );
        }
      }
    }
    return steps;
  }

  void _openSessionOverview(TrainingSessionTemplate session) {
    if (_steps.isEmpty) return;
    final totalExerciseSteps =
        _steps.where((step) => step.type == WorkoutStepType.exercise).length;
    final completedExerciseSteps = _steps
        .asMap()
        .entries
        .where((entry) =>
            entry.value.type == WorkoutStepType.exercise && entry.key < _currentStepIndex)
        .length;
    final progress = totalExerciseSteps == 0 ? 0.0 : completedExerciseSteps / totalExerciseSteps;

    final exerciseKeys = <SessionExerciseConfig, String>{};
    final exerciseOrder = <SessionExerciseConfig>[];
    for (var g = 0; g < session.groups.length; g++) {
      final group = session.groups[g];
      for (var e = 0; e < group.exercises.length; e++) {
        final exercise = group.exercises[e];
        final key = '$g:$e';
        exerciseKeys[exercise] = key;
        exerciseOrder.add(exercise);
      }
    }

    final totalByKey = <String, int>{};
    for (var g = 0; g < session.groups.length; g++) {
      final group = session.groups[g];
      for (var e = 0; e < group.exercises.length; e++) {
        totalByKey['$g:$e'] = group.rounds;
      }
    }

    final completedByKey = <String, int>{};
    for (var i = 0; i < _steps.length; i++) {
      if (i >= _currentStepIndex) break;
      final step = _steps[i];
      if (step.type != WorkoutStepType.exercise || step.exercise == null) continue;
      final key = exerciseKeys[step.exercise!];
      if (key == null) continue;
      completedByKey[key] = (completedByKey[key] ?? 0) + 1;
    }

    String? currentKey;
    if (_currentStepIndex >= 0 && _currentStepIndex < _steps.length) {
      final currentStep = _steps[_currentStepIndex];
      if (currentStep.type == WorkoutStepType.exercise && currentStep.exercise != null) {
        currentKey = exerciseKeys[currentStep.exercise!];
      } else if (currentStep.type == WorkoutStepType.rest) {
        for (var i = _currentStepIndex - 1; i >= 0; i--) {
          final step = _steps[i];
          if (step.type == WorkoutStepType.exercise && step.exercise != null) {
            currentKey = exerciseKeys[step.exercise!];
            break;
          }
        }
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.themeColors;
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight * 0.85;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: colors.border.withValues(alpha: 0.35),
                                color: colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exerciseOrder.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final exercise = exerciseOrder[index];
                          final key = exerciseKeys[exercise] ?? '';
                          final total = totalByKey[key] ?? 0;
                          final completed = completedByKey[key] ?? 0;
                          final isCurrent = key == currentKey;
                          final isDone = total > 0 && completed >= total;
                          final emoji = isDone
                              ? '✅'
                              : isCurrent
                                  ? '⏳'
                                  : '⭕️';
                          final name = exercise.exercise?.name ?? 'Exercice';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.cardBackgroundAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      if (total > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '$completed / $total',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startFromRecap() {
    if (_steps.isEmpty) return;
    _setSessionAwake(true);

    // IMPORTANT: On iOS, we MUST play audio immediately on user click
    // This unlocks the audio context for future plays
    if (_soundEnabled && !_audioUnlocked) {
      audioService.unlock(); // This plays a beep immediately
      setState(() => _audioUnlocked = true);
    }

    final profile = ref.read(appDataProvider).profile;
    final startSeconds = profile.startTimerSeconds;
    if (startSeconds <= 0) {
      _startWorkout();
      return;
    }
    _stage = WorkoutStage.countdown;
    _remainingSeconds = startSeconds;
    setState(() {});
    _startCountdownTimer();
    _persistPendingWorkout();
  }

  void _startWorkout() {
    _stage = WorkoutStage.running;
    _currentStepIndex = 0;
    _elapsedSeconds = 0;
    _paused = false;
    _completedSession = null;
    _startElapsedTimer();
    _startStep();
    _persistPendingWorkout();
  }

  void _startCountdownTimer({bool preserveRemaining = false}) {
    _timer?.cancel();
    if (!preserveRemaining) {
      final profile = ref.read(appDataProvider).profile;
      _remainingSeconds = profile.startTimerSeconds;
    }
    if (_remainingSeconds <= 0) {
      _startWorkout();
      return;
    }
    if (_soundEnabled) {
      _playBeep();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 3 && _remainingSeconds >= 1) {
        _playBeep();
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _startWorkout();
        return;
      }
      setState(() => _remainingSeconds -= 1);
      _persistPendingWorkout();
    });
  }

  void _startStep({bool preserveRemaining = false}) {
    _timer?.cancel();
    final step = _steps[_currentStepIndex];
    if (step.type == WorkoutStepType.rest || step.isTimedExercise) {
      if (!preserveRemaining) {
        _remainingSeconds = step.durationSeconds;
      }
      setState(() {});
      if (_remainingSeconds <= 0) {
        _advanceStep();
        return;
      }
      if (_remainingSeconds <= 3 && _remainingSeconds >= 1) {
        _playBeep();
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_paused) return;
        if (_remainingSeconds <= 3 && _remainingSeconds >= 1) {
          _playBeep();
        }
        if (_remainingSeconds <= 1) {
          timer.cancel();
          _playBeep();
          _advanceStep();
          return;
        }
        setState(() => _remainingSeconds -= 1);
        _persistPendingWorkout();
      });
      _persistPendingWorkout();
      return;
    }
    setState(() {});
    _persistPendingWorkout();
  }

  void _advanceStep() {
    if (_currentStepIndex + 1 >= _steps.length) {
      _finishCurrent();
      return;
    }
    var nextIndex = _currentStepIndex + 1;
    while (nextIndex < _steps.length &&
        _steps[nextIndex].type == WorkoutStepType.rest &&
        _isLastExerciseRest(nextIndex)) {
      nextIndex += 1;
    }
    if (nextIndex >= _steps.length) {
      _finishCurrent();
      return;
    }
    _currentStepIndex = nextIndex;
    _startStep();
    _persistPendingWorkout();
  }

  Future<void> _finishCurrent() async {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    final state = ref.read(appDataProvider);
    final session = state.sessions.firstWhere(
      (s) => s.id == widget.sessionId,
      orElse: () => TrainingSessionTemplate(
        id: '',
        name: 'Séance',
        notes: null,
        groups: const [],
      ),
    );
    if (session.id.isEmpty) return;

    final now = DateTime.now();
    final exerciseLogs = <WorkoutExerciseLog>[];

    for (final group in session.groups) {
      for (final exercise in group.exercises) {
        final sets = List.generate(
          group.rounds,
          (index) => WorkoutSetLog(
            setIndex: index + 1,
            reps: exercise.isTimed ? 0 : exercise.targetReps,
            seconds: exercise.isTimed ? exercise.targetSeconds : 0,
            weight: exercise.loadType == 'weight' ? exercise.loadValue : 0,
            loadType: exercise.loadType,
            loadMode: exercise.loadMode,
            rir: null,
          ),
        );
        exerciseLogs.add(
          WorkoutExerciseLog(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exercise?.name ?? 'Exercice',
            sets: sets,
          ),
        );
      }
    }

    final workout = WorkoutSessionLog(
      id: _uuid.v4(),
      sessionId: session.id,
      name: session.name,
      dateIso: now.toIso8601String(),
      durationMinutes: (_elapsedSeconds / 60).round(),
      exerciseLogs: exerciseLogs,
    );

    await ref.read(appDataProvider.notifier).addWorkoutSession(workout);
    if (!mounted) return;
    setState(() {
      _completedSession = workout;
      _stage = WorkoutStage.summary;
    });
    _setSessionAwake(false);
    workoutActive.value = false;
    await _clearPendingWorkout();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      setState(() => _elapsedSeconds += 1);
      _persistPendingWorkout();
    });
  }

  String _formatElapsed(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  WorkoutStep? _nextExerciseStep() {
    for (var i = _currentStepIndex + 1; i < _steps.length; i++) {
      final step = _steps[i];
      if (step.type == WorkoutStepType.exercise) {
        return step;
      }
    }
    return null;
  }

  WorkoutStep? _nextCircuitExercise(WorkoutStep current) {
    if (!current.isCircuitExercise ||
        current.round == null ||
        current.circuitIndex == null) {
      return null;
    }
    final targetIndex = current.circuitIndex! + 1;
    for (var i = _currentStepIndex + 1; i < _steps.length; i++) {
      final step = _steps[i];
      if (!step.isCircuitExercise || step.round != current.round) {
        if (step.round != current.round) return null;
        continue;
      }
      if (step.circuitIndex == targetIndex) {
        return step;
      }
    }
    return null;
  }

  List<WorkoutStep> _collectCircuitRoundSteps(int startIndex) {
    if (startIndex < 0 || startIndex >= _steps.length) return const [];
    final first = _steps[startIndex];
    if (!first.isCircuitExercise || first.round == null) return const [];
    final round = first.round;
    final collected = <WorkoutStep>[];
    for (var i = startIndex; i < _steps.length; i++) {
      final step = _steps[i];
      if (!step.isCircuitExercise || step.round != round) break;
      collected.add(step);
    }
    return collected;
  }

  String? _previousExerciseName() {
    for (var i = _currentStepIndex - 1; i >= 0; i--) {
      final step = _steps[i];
      if (step.type == WorkoutStepType.exercise) {
        return step.title;
      }
    }
    return null;
  }

  bool _isLastExerciseRest(int restIndex) {
    if (restIndex <= 0 || restIndex >= _steps.length) return false;
    final prev = _steps[restIndex - 1];
    if (prev.type != WorkoutStepType.exercise) return false;
    final nextExercise = _steps.skip(restIndex + 1).any((step) => step.type == WorkoutStepType.exercise);
    return !nextExercise;
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _persistPendingWorkout();
  }

  void _toggleSound() {
    final next = !_soundEnabled;
    setState(() => _soundEnabled = next);
    final profile = ref.read(appDataProvider).profile;
    ref.read(appDataProvider.notifier).updateProfile(
          profile.copyWith(soundEnabled: next),
        );
    // Unlock audio on iOS Safari/PWA when enabling sound
    if (next) {
      audioService.unlock();
    }
  }

  void _playBeep() {
    if (!_soundEnabled) return;
    audioService.playBeep();
  }

  void _goBack() {
    _setSessionAwake(false);
    unawaited(_clearPendingWorkout());
    if (!mounted) return;
    context.go('/');
  }

  void _restartFromSummary() {
    setState(() {
      _completedSession = null;
      _stage = WorkoutStage.recap;
      _currentStepIndex = 0;
      _remainingSeconds = 0;
      _elapsedSeconds = 0;
      _paused = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      workoutActive.value = true;
    });
    _persistPendingWorkout();
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
                  'Arrêter la séance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirmer l’arrêt de la séance ?',
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
                          child: const Text('Arrêter', style: TextStyle(fontSize: 18)),
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
    _timer?.cancel();
    _elapsedTimer?.cancel();
    _setSessionAwake(false);
    workoutActive.value = false;
    await _clearPendingWorkout();
    if (!mounted) return;
    context.go('/');
  }

  void _persistPendingWorkout() {
    if (!_sessionReady) return;
    if (widget.sessionId == null || widget.sessionId!.isEmpty) return;
    final stage = switch (_stage) {
      WorkoutStage.countdown => PendingWorkoutStage.countdown,
      WorkoutStage.running => PendingWorkoutStage.running,
      _ => null,
    };
    if (stage == null) return;

    final session = ref.read(appDataProvider).sessions.firstWhere(
          (s) => s.id == widget.sessionId,
          orElse: () => TrainingSessionTemplate(
            id: widget.sessionId!,
            name: 'Séance',
            notes: null,
            groups: const [],
          ),
        );

    final payload = PendingWorkoutState(
      sessionId: widget.sessionId!,
      sessionName: session.name,
      stage: stage,
      currentStepIndex: _currentStepIndex,
      remainingSeconds: _remainingSeconds,
      elapsedSeconds: _elapsedSeconds,
      paused: _paused,
    );

    unawaited(
      ref
          .read(storageProvider)
          .setString(StorageService.pendingWorkoutKey, payload.toStorageString()),
    );
  }

  Future<void> _clearPendingWorkout() {
    return ref.read(storageProvider).delete(StorageService.pendingWorkoutKey);
  }

  void _setSessionAwake(bool enabled) {
    if (_wakeLockHeld == enabled) return;
    _wakeLockHeld = enabled;
    unawaited(enabled ? WakelockPlus.enable() : WakelockPlus.disable());
  }
}
