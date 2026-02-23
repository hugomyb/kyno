import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/program.dart';
import '../../models/session_template.dart';
import '../../providers/app_data_provider.dart';
import '../widgets/app_background.dart';

class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key});

  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appDataProvider);
    final program = state.program;
    final sessions = state.sessions;
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Programme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sessions.length} séances disponibles',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/sessions'),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('Mes séances'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (var day = 1; day <= 7; day++) ...[
                  _dayCard(context, program, sessions, day, today == day),
                  const SizedBox(height: 12),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Aujourd’hui',
                        style: TextStyle(
                          color: Colors.white,
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
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                '$exercisesCount exercices',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openSessionPicker(context, program, sessions, day, currentSessionId),
          ),
          children: [
            if (exercisesCount == 0)
              const Text(
                'Aucun exercice.',
                style: TextStyle(color: Color(0xFF64748B)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Exercice $blockIndex',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBE7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Circuit $blockIndex',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _badgePill(
                Icons.repeat,
                '${group.rounds} ${group.rounds == 1 ? 'tour' : 'tours'}',
              ),
              const SizedBox(width: 8),
              _badgePill(Icons.timer, '${group.restBetweenRoundsSeconds}s repos'),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              for (var i = 0; i < group.exercises.length; i++) ...[
                _exerciseRow(i + 1, group, group.exercises[i]),
                if (i != group.exercises.length - 1)
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
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
    final name = exercise.exercise?.name ?? 'Exercice';
    final target = exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps';
    final rest = '${group.restBetweenRoundsSeconds}s';
    final sets = group.exercises.length > 1
        ? '${group.rounds} tours'
        : '${group.rounds} ${group.rounds == 1 ? 'série' : 'séries'}';
    final load = exercise.loadType == 'bodyweight'
        ? 'PDC'
        : '${exercise.loadValue}kg ${exercise.loadMode == 'per_hand' ? '/main' : 'total'}';
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
              color: const Color(0xFFE7EEFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7E3FF)),
            ),
            child: Text(
              '$index',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2F5FE3), fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!isCircuit) _badgePill(Icons.repeat, sets),
                  _badgePill(Icons.fitness_center, target),
                  if (!isCircuit) _badgePill(Icons.timer, rest),
                  _badgePill(Icons.scale, load),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badgePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2F5FE3)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F5FE3),
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
