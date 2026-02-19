import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../providers/app_state_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(appStateProvider).program;

    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (program.notes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFCBD5F1).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_graph,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Regles de progression',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...program.notes
                            .split('\n')
                            .where((line) => line.trim().isNotEmpty)
                            .map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _stripBulletPrefix(line),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: const Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5F1).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (var day = 1; day <= 7; day++)
                  _dayCard(context, ref, program, day),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
    int day,
  ) {
    final session = program.sessions.firstWhere(
      (s) => s.dayOfWeek == day,
      orElse: () => WorkoutSessionTemplate(
        id: 'day_$day',
        name: _dayLabel(day),
        exercises: const [],
        restSeconds: 90,
        estimatedDurationSeconds: 0,
        order: day,
        dayOfWeek: day,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColorDark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
          title: Text(
            _dayLabel(day),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            session.exercises.isEmpty
                ? 'Repos'
                : '${session.name} · ${session.exercises.length} exercices',
          ),
          trailing: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              tooltip: 'Renommer',
              onPressed: () => _showEditSessionNameSheet(context, ref, program, day),
            ),
          ),
          children: [
            for (var i = 0; i < session.exercises.length; i++) ...[
              ListTile(
                title: Row(
                  children: [
                    _indexBadge(i + 1),
                    const SizedBox(width: 10),
                    Expanded(child: Text(session.exercises[i].name)),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _exerciseBadges(session.exercises[i]),
                  ),
                ),
                onTap: () => _showEditExerciseSheet(
                  context,
                  ref,
                  program,
                  session,
                  session.exercises[i],
                ),
              ),
              if (i != session.exercises.length - 1)
                const Divider(height: 12, thickness: 0.6),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _exerciseBadges(ExerciseTemplate exercise) {
    final badges = <Widget>[
      _iconBadge(Icons.repeat, '${exercise.sets}'),
      if (exercise.isTimed)
        _iconBadge(Icons.timer_outlined, '${exercise.durationSeconds}s')
      else
        _iconBadge(Icons.fitness_center, '${exercise.targetReps}'),
      _iconBadge(Icons.snooze, '${exercise.restSeconds}s'),
    ];
    if (exercise.loadText.isNotEmpty) {
      badges.add(_iconBadge(Icons.scale_outlined, exercise.loadText));
    }
    return badges;
  }

  Widget _iconBadge(IconData icon, String label) {
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

  String _dayLabel(int day) {
    return switch (day) {
      1 => 'Lundi',
      2 => 'Mardi',
      3 => 'Mercredi',
      4 => 'Jeudi',
      5 => 'Vendredi',
      6 => 'Samedi',
      _ => 'Dimanche',
    };
  }

  String _stripBulletPrefix(String input) {
    var text = input.trimLeft();
    while (text.isNotEmpty) {
      final ch = text[0];
      if (ch == '•' || ch == '-' || ch == '*' || ch == '–' || ch == '—') {
        text = text.substring(1).trimLeft();
        continue;
      }
      if (ch.trim().isEmpty) {
        text = text.substring(1);
        continue;
      }
      break;
    }
    return text;
  }

  Future<void> _showEditExerciseSheet(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
    WorkoutSessionTemplate session,
    ExerciseTemplate exercise,
  ) async {
    final nameController = TextEditingController(text: exercise.name);
    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.targetReps);
    final secondsController = TextEditingController(text: exercise.durationSeconds.toString());
    final restController = TextEditingController(text: exercise.restSeconds.toString());
    final loadController = TextEditingController(text: exercise.loadText);
    var isTimed = exercise.isTimed;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  Text(
                    'Modifier exercice',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Series'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Exercice en secondes'),
                    value: isTimed,
                    onChanged: (value) {
                      setSheetState(() => isTimed = value);
                    },
                  ),
                  if (isTimed)
                    TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Secondes par serie'),
                    )
                  else
                    TextField(
                      controller: repsController,
                      decoration: const InputDecoration(labelText: 'Reps par serie'),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: restController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repos (secondes)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: loadController,
                    decoration: const InputDecoration(labelText: 'Charge (ex: PDC, 6-8 kg/main)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final updated = ExerciseTemplate(
                              id: exercise.id,
                              name: nameController.text.trim(),
                              sets: int.tryParse(setsController.text.trim()) ?? exercise.sets,
                              targetReps: repsController.text.trim().isEmpty
                                  ? exercise.targetReps
                                  : repsController.text.trim(),
                              targetWeight: exercise.targetWeight,
                              loadText: loadController.text.trim(),
                              tempo: exercise.tempo,
                              notes: exercise.notes,
                              restSeconds:
                                  int.tryParse(restController.text.trim()) ?? exercise.restSeconds,
                              isTimed: isTimed,
                              durationSeconds:
                                  int.tryParse(secondsController.text.trim()) ??
                                      exercise.durationSeconds,
                            );

                            final updatedExercises = session.exercises
                                .map((e) => e.id == updated.id ? updated : e)
                                .toList();

                            final updatedSession = WorkoutSessionTemplate(
                              id: session.id,
                              name: session.name,
                              exercises: updatedExercises,
                              restSeconds: session.restSeconds,
                              estimatedDurationSeconds: session.estimatedDurationSeconds,
                              order: session.order,
                              dayOfWeek: session.dayOfWeek,
                            );

                            final sessions = program.sessions
                                .where((s) => s.dayOfWeek != session.dayOfWeek)
                                .toList()
                              ..add(updatedSession);

                            ref.read(appStateProvider.notifier).updateProgram(
                                  WorkoutProgram(
                                    id: program.id,
                                    title: program.title,
                                    sessions: sessions,
                                    notes: program.notes,
                                  ),
                                );
                            ref.read(appStateProvider.notifier).save();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSessionNameSheet(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
    int day,
  ) async {
    final existingSession = program.sessions.firstWhere(
      (s) => s.dayOfWeek == day,
      orElse: () => WorkoutSessionTemplate(
        id: 'day_$day',
        name: _dayLabel(day),
        exercises: const [],
        restSeconds: 90,
        estimatedDurationSeconds: 0,
        order: day,
        dayOfWeek: day,
      ),
    );
    final nameController = TextEditingController(text: existingSession.name);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
              Text(
                'Renommer la seance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final updatedSession = WorkoutSessionTemplate(
                          id: existingSession.id,
                          name: nameController.text.trim().isEmpty
                              ? _dayLabel(day)
                              : nameController.text.trim(),
                          exercises: existingSession.exercises,
                          restSeconds: existingSession.restSeconds,
                          estimatedDurationSeconds: existingSession.estimatedDurationSeconds,
                          order: existingSession.order,
                          dayOfWeek: existingSession.dayOfWeek,
                        );

                        final sessions = program.sessions
                            .where((s) => s.dayOfWeek != day)
                            .toList()
                          ..add(updatedSession);

                        ref.read(appStateProvider.notifier).updateProgram(
                              WorkoutProgram(
                                id: program.id,
                                title: program.title,
                                sessions: sessions,
                                notes: program.notes,
                              ),
                            );
                        ref.read(appStateProvider.notifier).save();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
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
}
