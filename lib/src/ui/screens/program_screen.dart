import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/program.dart';
import '../../models/session_template.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/number_format.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key});

  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final state = ref.watch(appDataProvider);
    final program = state.program;
    final sessions = state.sessions;
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Programme',
        subtitle: 'Votre plan d\'entraînement',
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors.isDark
                          ? [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            ]
                          : [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                              const Color(0xFFA78BFA).withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colors.isDark
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                          : const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: colors.isDark ? 0.2 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: colors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Votre programme',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sessions.length} séances disponibles',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/sessions'),
                          icon: const Icon(Icons.list_alt, size: 20),
                          label: const Text('Mes séances', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (var day = 1; day <= 7; day++) ...[
                  _dayCard(context, program, sessions, day, today == day),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(
    BuildContext context,
    Program program,
    List<TrainingSessionTemplate> sessions,
    int day,
    bool isToday,
  ) {
    final existing = program.days.where((d) => d.dayOfWeek == day).toList();
    final currentSessionId = existing.isEmpty ? '' : (existing.first.sessionId ?? '');
    final selectedSession = currentSessionId.isEmpty
        ? null
        : sessions.firstWhere(
            (s) => s.id == currentSessionId,
            orElse: () => TrainingSessionTemplate(
              id: '',
              name: '',
              notes: null,
              groups: const [],
            ),
          );

    final sessionGroups = selectedSession?.groups ?? const <SessionGroup>[];
    final exercisesCount = sessionGroups.fold<int>(
      0,
      (sum, group) => sum + group.exercises.length,
    );

    final colors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isToday
              ? colors.primary.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.5),
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : colors.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 12, bottom: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _dayLabel(day),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Aujourd’hui',
                        style: TextStyle(
                          color: colors.isDark ? colors.textPrimary : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                currentSessionId.isEmpty ? 'Repos' : (selectedSession?.name ?? 'Séance'),
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '$exercisesCount exercices',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openSessionPicker(context, program, sessions, day, currentSessionId),
          ),
          children: [
            if (exercisesCount == 0)
              Text(
                'Aucun exercice.',
                style: TextStyle(color: colors.textSecondary),
              ),
            if (exercisesCount > 0)
              Column(
                children: _buildExerciseList(sessionGroups),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseList(List<SessionGroup> groups) {
    final widgets = <Widget>[];
    var blockIndex = 0;

    for (final group in groups) {
      if (group.exercises.isEmpty) {
        continue;
      }
      blockIndex += 1;
      if (group.exercises.length > 1) {
        widgets.add(_circuitBlock(blockIndex, group));
      } else {
        widgets.add(_singleBlock(blockIndex, group, group.exercises.first));
      }
      widgets.add(const SizedBox(height: 12));
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }
    return widgets;
  }

  Widget _singleBlock(int blockIndex, SessionGroup group, SessionExerciseConfig exercise) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.chipBackground(colors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Exercice $blockIndex',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _exerciseRow(1, group, exercise, showIndex: false),
        ],
      ),
    );
  }

  Widget _circuitBlock(int blockIndex, SessionGroup group) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackgroundAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.chipBackground(colors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Circuit $blockIndex',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _badgePill(
                context,
                Icons.repeat,
                '${group.rounds} ${group.rounds == 1 ? 'tour' : 'tours'}',
              ),
              const SizedBox(width: 8),
              _badgePill(context, Icons.timer, '${group.restBetweenRoundsSeconds}s repos'),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              for (var i = 0; i < group.exercises.length; i++) ...[
                _exerciseRow(i + 1, group, group.exercises[i]),
                if (i != group.exercises.length - 1)
                  Divider(height: 20, color: colors.border),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateProgramDay(
    AppDataNotifier notifier,
    Program program,
    int day,
    String sessionId,
  ) async {
    final days = [...program.days];
    days.removeWhere((d) => d.dayOfWeek == day);
    if (sessionId.isNotEmpty) {
      days.add(ProgramDay(id: null, dayOfWeek: day, sessionId: sessionId, orderIndex: 0));
    }
    await notifier.updateProgram(
          Program(id: program.id, title: program.title, notes: program.notes, days: days),
        );
  }

  Future<void> _openSessionPicker(
    BuildContext context,
    Program program,
    List<TrainingSessionTemplate> sessions,
    int day,
    String currentSessionId,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choisir une séance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: currentSessionId.isEmpty ? null : currentSessionId,
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Repos'),
                  ),
                  ...sessions.map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (value) => Navigator.of(context).pop(value ?? ''),
                decoration: const InputDecoration(labelText: 'Séance'),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    await _updateProgramDay(ref.read(appDataProvider.notifier), program, day, selected);
  }

  Widget _exerciseRow(
    int index,
    SessionGroup group,
    SessionExerciseConfig exercise, {
    bool showIndex = true,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.themeColors;
    final name = exercise.exercise?.name ?? 'Exercice';
    final target = exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps';
    final rest = '${group.restBetweenRoundsSeconds}s';
    final sets = group.exercises.length > 1
        ? '${group.rounds} tours'
        : '${group.rounds} ${group.rounds == 1 ? 'série' : 'séries'}';
    final load = exercise.loadType == 'bodyweight'
        ? 'PDC'
        : '${formatDecimalFr(exercise.loadValue)}kg ${exercise.loadMode == 'per_hand' ? '/main' : 'total'}';
    final isCircuit = group.exercises.length > 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIndex) ...[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.chipBackground(colors.primary),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!isCircuit) _badgePill(context, Icons.repeat, sets),
                      _badgePill(context, Icons.fitness_center, target),
                      if (!isCircuit) _badgePill(context, Icons.timer, rest),
                      _badgePill(context, Icons.scale, load),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _badgePill(BuildContext context, IconData icon, String label) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.chipBackground(colors.primary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int day) {
    switch (day) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Jour';
    }
  }
}
