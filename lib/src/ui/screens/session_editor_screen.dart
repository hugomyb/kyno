import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/exercise.dart';
import '../../models/session_template.dart';
import '../../providers/app_data_provider.dart';
import '../widgets/app_background.dart';

class SessionEditorScreen extends ConsumerStatefulWidget {
  const SessionEditorScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends ConsumerState<SessionEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final _uuid = const Uuid();
  List<SessionGroup> _groups = [];
  final List<bool> _groupIsCircuit = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(appDataProvider);
    final existing = widget.sessionId == null
        ? null
        : state.sessions.firstWhere(
            (s) => s.id == widget.sessionId,
            orElse: () => TrainingSessionTemplate(
              id: '',
              name: '',
              notes: null,
              groups: const [],
            ),
          );

    _nameController = TextEditingController(text: existing?.name ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _groups = existing?.groups.map(_cloneGroup).toList() ?? [];
    _groups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (final group in _groups) {
      _groupIsCircuit.add(group.exercises.length > 1);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(appDataProvider).exercises;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer séance'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBlockSheet(exercises),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un exercice'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Enregistrer'),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF4FF), Color(0xFFF8FAFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFD7E3FF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.edit_note, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Informations',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      )),
                                  SizedBox(height: 2),
                                  Text(
                                    'Nom de la séance + notes',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nom de la séance'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _groups.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _groups.removeAt(oldIndex);
                        _groups.insert(newIndex, item);
                        final flag = _groupIsCircuit.removeAt(oldIndex);
                        _groupIsCircuit.insert(newIndex, flag);
                      });
                    },
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return Dismissible(
                        key: ValueKey('group-${group.orderIndex}-$index'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDeleteBlock(context),
                        onDismissed: (_) => setState(() {
                          _groups.removeAt(index);
                          _groupIsCircuit.removeAt(index);
                        }),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                        ),
                        child: _blockCard(group, index, exercises),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockCard(SessionGroup group, int index, List<Exercise> exercises) {
    final isCircuit = _groupIsCircuit[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCircuit ? const Color(0xFFF4F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCircuit ? const Color(0xFFD7E3FF) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditBlockSheet(group, index, exercises),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCircuit ? const Color(0xFFDBE7FF) : const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCircuit ? 'Circuit ${index + 1}' : 'Exercice ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const Spacer(),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isCircuit) ..._singleSummary(group) else ..._circuitSummary(group),
          ],
        ),
      ),
    );
  }

  List<Widget> _singleSummary(SessionGroup group) {
    final exercise = group.exercises.isEmpty ? null : group.exercises.first;
    if (exercise == null) {
      return [
        const Text('Exercice non défini', style: TextStyle(color: Color(0xFF64748B))),
      ];
    }
    final name = exercise.exercise?.name ??
        (exercise.exerciseId.isEmpty ? 'Exercice non défini' : 'Exercice');
    final target = exercise.isTimed
        ? '${exercise.targetSeconds}s'
        : '${exercise.targetReps} reps';
    final load = exercise.loadType == 'bodyweight'
        ? 'PDC'
        : '${exercise.loadValue} kg ${exercise.loadMode == 'per_hand' ? '/main' : 'total'}';

    return [
      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _badgePill(
            Icons.repeat,
            '${group.rounds} ${group.rounds == 1 ? 'série' : 'séries'}',
          ),
          _badgePill(Icons.fitness_center, target),
          _badgePill(Icons.timer, '${group.restBetweenRoundsSeconds}s repos'),
          _badgePill(Icons.scale, load),
        ],
      ),
    ];
  }

  List<Widget> _circuitSummary(SessionGroup group) {
    return [
      Row(
        children: [
          const Icon(Icons.autorenew, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            'Circuit — ${group.rounds} tours',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          _badgePill(Icons.timer, '${group.restBetweenRoundsSeconds}s repos'),
        ],
      ),
      const SizedBox(height: 6),
      for (final exercise in group.exercises)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.exercise?.name ?? 'Exercice',
                style: const TextStyle(color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _badgePill(
                    Icons.fitness_center,
                    exercise.isTimed ? '${exercise.targetSeconds}s' : '${exercise.targetReps} reps',
                  ),
                  _badgePill(
                    Icons.scale,
                    exercise.loadType == 'bodyweight'
                        ? 'PDC'
                        : '${exercise.loadValue} kg ${exercise.loadMode == 'per_hand' ? '/main' : 'total'}',
                  ),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  Widget _badgePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteBlock(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le bloc ?'),
          content: const Text('Cette action est irreversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddBlockSheet(List<Exercise> exercises) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter à la séance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _selectTile(
                context,
                title: 'Exercice',
                subtitle: 'Un seul exercice par bloc',
                icon: Icons.fitness_center,
                value: 'single',
              ),
              const SizedBox(height: 10),
              _selectTile(
                context,
                title: 'Circuit',
                subtitle: 'Autant d’exercices que tu veux',
                icon: Icons.autorenew,
                value: 'circuit',
              ),
            ],
          ),
        );
      },
    );

    if (type == null) return;

    final group = type == 'single' ? _buildEmptySingleBlock() : _buildEmptyCircuitBlock();
    setState(() {
      _groups.add(group);
      _groupIsCircuit.add(type == 'circuit');
    });
    final index = _groups.length - 1;
    await _openEditBlockSheet(group, index, exercises);
  }

  Widget _selectTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  SessionGroup _buildEmptySingleBlock() {
    return SessionGroup(
      orderIndex: _groups.length,
      rounds: 1,
      restBetweenRoundsSeconds: 0,
      exercises: [
        SessionExerciseConfig(
          exerciseId: '',
          orderIndex: 0,
          targetType: 'reps',
          targetReps: 0,
          targetSeconds: 0,
          restSeconds: 0,
          loadType: 'bodyweight',
          loadValue: 0,
          loadMode: 'total',
          notes: null,
          exercise: null,
        )
      ],
    );
  }

  SessionGroup _buildEmptyCircuitBlock() {
    return SessionGroup(
      orderIndex: _groups.length,
      rounds: 1,
      restBetweenRoundsSeconds: 0,
      exercises: [],
    );
  }

  Future<bool> _openEditBlockSheet(
    SessionGroup group,
    int groupIndex,
    List<Exercise> exercises,
  ) async {
    final isCircuit = _groupIsCircuit[groupIndex];
    final controllers = <String, TextEditingController>{};
    int? expandedExerciseIndex = group.exercises.isEmpty
        ? null
        : group.exercises.indexWhere((e) => e.exerciseId.isEmpty);
    if (expandedExerciseIndex != null && expandedExerciseIndex == -1) {
      expandedExerciseIndex = null;
    }
    void syncGroup(SessionGroup nextGroup) {
      if (!mounted) return;
      setState(() => _groups[groupIndex] = nextGroup);
    }
    String fmtInt(int value) => value == 0 ? '' : value.toString();
    TextEditingController ctrl(String key, String value) {
      return controllers.putIfAbsent(key, () => TextEditingController(text: value));
    }
    void setCtrl(String key, String value) {
      final ctrl = controllers[key];
      if (ctrl == null) return;
      ctrl.text = value;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
    var localGroup = _cloneGroup(group);
    final edited = await showModalBottomSheet<SessionGroup>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (isCircuit) ...[
                        Center(
                          child: Text(
                            'Circuit',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            '${localGroup.rounds} tours • ${localGroup.restBetweenRoundsSeconds}s repos',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: Text(
                            'Exercice',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            '${localGroup.rounds} séries • ${localGroup.restBetweenRoundsSeconds}s repos',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                      if (isCircuit)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Les exercices s’enchaînent. Repos à la fin du tour.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: isCircuit ? 'Tours' : 'Séries',
                                  hintText: '0',
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                ),
                                controller: ctrl('group-rounds', fmtInt(localGroup.rounds)),
                                onChanged: (value) {
                                  final rounds = int.tryParse(value) ?? 0;
                                  setModalState(() {
                                    localGroup = SessionGroup(
                                      orderIndex: localGroup.orderIndex,
                                      rounds: rounds,
                                      restBetweenRoundsSeconds:
                                          localGroup.restBetweenRoundsSeconds,
                                      exercises: localGroup.exercises,
                                    );
                                  });
                                  syncGroup(localGroup);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: isCircuit
                                      ? 'Repos après tour (s)'
                                      : 'Repos entre séries (s)',
                                  hintText: '0',
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                ),
                                controller: ctrl(
                                  'group-rest',
                                  fmtInt(localGroup.restBetweenRoundsSeconds),
                                ),
                                onChanged: (value) {
                                  final rest = int.tryParse(value) ?? 0;
                                  setModalState(() {
                                    localGroup = SessionGroup(
                                      orderIndex: localGroup.orderIndex,
                                      rounds: localGroup.rounds,
                                      restBetweenRoundsSeconds: rest,
                                      exercises: localGroup.exercises,
                                    );
                                  });
                                  syncGroup(localGroup);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            if (isCircuit) ...[
                              const Text(
                                'Circuit',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ajoute autant d’exercices que tu veux, puis règle les détails ici.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              if (localGroup.exercises.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Aucun exercice dans ce circuit',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: () {
                                          _showExercisePicker(
                                            context,
                                            exercises,
                                            Exercise(
                                              id: '',
                                              name: 'Exercice',
                                              categories: const <String>[],
                                              userId: null,
                                            ),
                                          ).then((picked) {
                                            if (picked == null) return;
                                            final list = [...localGroup.exercises];
                                            list.add(
                                              SessionExerciseConfig(
                                                exerciseId: picked.id,
                                                orderIndex: list.length,
                                                targetType: 'reps',
                                                targetReps: 0,
                                                targetSeconds: 0,
                                                restSeconds: 0,
                                                loadType: 'bodyweight',
                                                loadValue: 0,
                                                loadMode: 'total',
                                                notes: null,
                                                exercise: picked,
                                              ),
                                            );
                                            final nextGroup = SessionGroup(
                                              orderIndex: localGroup.orderIndex,
                                              rounds: localGroup.rounds,
                                              restBetweenRoundsSeconds:
                                                  localGroup.restBetweenRoundsSeconds,
                                              exercises: list,
                                            );
                                            setModalState(() => localGroup = nextGroup);
                                            syncGroup(localGroup);
                                          });
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Ajouter un exercice'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              for (var i = 0; i < localGroup.exercises.length; i++)
                                _circuitExerciseInline(
                                  exercises,
                                  localGroup,
                                  i,
                                  controllers,
                                  setCtrl,
                                  expanded: expandedExerciseIndex == i,
                                  onChanged: (updated) {
                                    setModalState(() {
                                      final list = [...localGroup.exercises];
                                      list[i] = updated;
                                      localGroup = SessionGroup(
                                        orderIndex: localGroup.orderIndex,
                                        rounds: localGroup.rounds,
                                        restBetweenRoundsSeconds:
                                            localGroup.restBetweenRoundsSeconds,
                                        exercises: list,
                                      );
                                    });
                                    syncGroup(localGroup);
                                  },
                                  onRemove: () {
                                    setModalState(() {
                                      final list = [...localGroup.exercises]..removeAt(i);
                                      if (expandedExerciseIndex != null) {
                                        if (expandedExerciseIndex == i) {
                                          expandedExerciseIndex = null;
                                        } else if (expandedExerciseIndex! > i) {
                                          expandedExerciseIndex = expandedExerciseIndex! - 1;
                                        }
                                      }
                                      localGroup = SessionGroup(
                                        orderIndex: localGroup.orderIndex,
                                        rounds: localGroup.rounds,
                                        restBetweenRoundsSeconds:
                                            localGroup.restBetweenRoundsSeconds,
                                        exercises: list,
                                      );
                                    });
                                    syncGroup(localGroup);
                                  },
                                  onToggleExpanded: () {
                                    setModalState(() {
                                      expandedExerciseIndex = expandedExerciseIndex == i ? null : i;
                                    });
                                  },
                                ),
                              if (localGroup.exercises.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () {
                                    _showExercisePicker(
                                      context,
                                      exercises,
                                      Exercise(
                                        id: '',
                                        name: 'Exercice',
                                        categories: const <String>[],
                                        userId: null,
                                      ),
                                    ).then((picked) {
                                      if (picked == null) return;
                                      final list = [...localGroup.exercises];
                                      list.add(
                                        SessionExerciseConfig(
                                          exerciseId: picked.id,
                                          orderIndex: list.length,
                                          targetType: 'reps',
                                          targetReps: 0,
                                          targetSeconds: 0,
                                          restSeconds: 0,
                                          loadType: 'bodyweight',
                                          loadValue: 0,
                                          loadMode: 'total',
                                          notes: null,
                                          exercise: picked,
                                        ),
                                      );
                                      expandedExerciseIndex = list.length - 1;
                                      final nextGroup = SessionGroup(
                                        orderIndex: localGroup.orderIndex,
                                        rounds: localGroup.rounds,
                                        restBetweenRoundsSeconds:
                                            localGroup.restBetweenRoundsSeconds,
                                        exercises: list,
                                      );
                                      setModalState(() => localGroup = nextGroup);
                                      syncGroup(localGroup);
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter un exercice'),
                                ),
                              ],
                            ],
                            if (!isCircuit && localGroup.exercises.isNotEmpty)
                              _singleExerciseInline(
                                exercises,
                                localGroup,
                                controllers,
                                setCtrl,
                                onChanged: (updated) {
                                    setModalState(() {
                                      final list = [...localGroup.exercises];
                                      list[0] = updated;
                                      localGroup = SessionGroup(
                                        orderIndex: localGroup.orderIndex,
                                        rounds: localGroup.rounds,
                                        restBetweenRoundsSeconds:
                                            localGroup.restBetweenRoundsSeconds,
                                        exercises: list,
                                      );
                                    });
                                    syncGroup(localGroup);
                                  },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final roundsValid = localGroup.rounds > 0;
                          final restValid = localGroup.restBetweenRoundsSeconds > 0;
                          final exercisesValid = localGroup.exercises.isNotEmpty &&
                              localGroup.exercises.every((e) {
                                final targetOk = e.targetType == 'time'
                                    ? e.targetSeconds > 0
                                    : e.targetReps > 0;
                                return e.exerciseId.isNotEmpty && targetOk;
                              });
                          final isValid = roundsValid && restValid && exercisesValid;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isValid)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Renseigne un exercice, des séries/tours, un repos et un objectif.',
                                    style: TextStyle(color: Color(0xFFEF4444)),
                                  ),
                                ),
                              FilledButton(
                                onPressed: isValid ? () => Navigator.of(context).pop(localGroup) : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Valider le bloc'),
                              ),
                            ],
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

    if (edited == null) return false;
    setState(() => _groups[groupIndex] = edited);
    return true;
  }

  Widget _singleExerciseInline(
    List<Exercise> exercises,
    SessionGroup group,
    Map<String, TextEditingController> controllers,
    void Function(String, String) setCtrl, {
    required void Function(SessionExerciseConfig) onChanged,
  }) {
    final exercise = group.exercises.first;
    final selected = exercise.exerciseId.isEmpty
        ? Exercise(id: '', name: 'Exercice', categories: const <String>[], userId: null)
        : exercises.firstWhere(
            (e) => e.id == exercise.exerciseId,
            orElse: () => exercise.exercise ??
                Exercise(id: '', name: 'Exercice', categories: const <String>[], userId: null),
          );
    final targetKey = 'single-target';
    final weightKey = 'single-weight';
    final targetController = controllers.putIfAbsent(
      targetKey,
      () => TextEditingController(
        text: exercise.targetType == 'time'
            ? (exercise.targetSeconds == 0 ? '' : exercise.targetSeconds.toString())
            : (exercise.targetReps == 0 ? '' : exercise.targetReps.toString()),
      ),
    );
    final weightController = controllers.putIfAbsent(
      weightKey,
      () => TextEditingController(
        text: exercise.loadValue == 0 ? '' : exercise.loadValue.toString(),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        _exercisePicker(
          context,
          exercises,
          selected,
          onPicked: (picked) {
            onChanged(
              exercise.copyWith(
                exerciseId: picked.id,
                exercise: picked,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Objectif',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            segments: const [
              ButtonSegment(value: 'reps', label: Text('Répétitions')),
              ButtonSegment(value: 'time', label: Text('Durée')),
            ],
            selected: {exercise.targetType},
            onSelectionChanged: (value) {
              final nextType = value.first;
              onChanged(exercise.copyWith(targetType: nextType));
            setCtrl(
              targetKey,
              nextType == 'time'
                  ? (exercise.targetSeconds == 0 ? '' : exercise.targetSeconds.toString())
                  : (exercise.targetReps == 0 ? '' : exercise.targetReps.toString()),
            );
            },
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          controller: targetController,
          decoration: InputDecoration(
            labelText: exercise.targetType == 'time' ? 'Secondes' : 'Répétitions',
            hintText: '0',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
          onChanged: (value) {
            final numValue = int.tryParse(value) ?? 0;
            onChanged(exercise.copyWith(
              targetReps: exercise.targetType == 'time' ? exercise.targetReps : numValue,
              targetSeconds: exercise.targetType == 'time' ? numValue : exercise.targetSeconds,
            ));
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Charge',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            segments: const [
              ButtonSegment(value: 'bodyweight', label: Text('PDC')),
              ButtonSegment(value: 'weight', label: Text('Poids')),
            ],
            selected: {exercise.loadType},
              onSelectionChanged: (value) {
                final nextType = value.first;
                onChanged(exercise.copyWith(
                  loadType: nextType,
                  loadValue: nextType == 'bodyweight' ? 0 : exercise.loadValue,
                  loadMode: nextType == 'bodyweight' ? 'total' : exercise.loadMode,
                ));
                if (nextType == 'bodyweight') {
                  setCtrl(weightKey, '');
                }
              },
          ),
        ),
        if (exercise.loadType == 'weight') ...[
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            controller: weightController,
            decoration: const InputDecoration(
              labelText: 'Poids (kg)',
              hintText: '0',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
            onChanged: (value) {
              onChanged(exercise.copyWith(loadValue: double.tryParse(value) ?? 0));
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              segments: const [
                ButtonSegment(value: 'total', label: Text('Total')),
                ButtonSegment(value: 'per_hand', label: Text('Par main')),
              ],
              selected: {exercise.loadMode},
              onSelectionChanged: (value) {
                onChanged(exercise.copyWith(loadMode: value.first));
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _circuitExerciseInline(
    List<Exercise> exercises,
    SessionGroup group,
    int index,
    Map<String, TextEditingController> controllers,
    void Function(String, String) setCtrl, {
    required bool expanded,
    required void Function(SessionExerciseConfig) onChanged,
    required VoidCallback onRemove,
    required VoidCallback onToggleExpanded,
  }) {
    final exercise = group.exercises[index];
    final selected = exercise.exerciseId.isEmpty
        ? Exercise(id: '', name: 'Exercice', categories: const <String>[], userId: null)
        : exercises.firstWhere(
            (e) => e.id == exercise.exerciseId,
            orElse: () => exercise.exercise ??
                Exercise(id: '', name: 'Exercice', categories: const <String>[], userId: null),
          );
    final targetKey = 'c-$index-target';
    final weightKey = 'c-$index-weight';
    final targetController = controllers.putIfAbsent(
      targetKey,
      () => TextEditingController(
        text: exercise.targetType == 'time'
            ? (exercise.targetSeconds == 0 ? '' : exercise.targetSeconds.toString())
            : (exercise.targetReps == 0 ? '' : exercise.targetReps.toString()),
      ),
    );
    final weightController = controllers.putIfAbsent(
      weightKey,
      () => TextEditingController(
        text: exercise.loadValue == 0 ? '' : exercise.loadValue.toString(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Exercice ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.name.isEmpty ? 'Sélectionner un exercice' : selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                iconSize: 24,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onToggleExpanded,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Replier la configuration' : 'Configurer cet exercice'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            _exercisePicker(
              context,
              exercises,
              selected,
              onPicked: (picked) {
                onChanged(exercise.copyWith(exerciseId: picked.id, exercise: picked));
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Objectif',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: 'reps', label: Text('Répétitions')),
                  ButtonSegment(value: 'time', label: Text('Durée')),
                ],
                selected: {exercise.targetType},
                onSelectionChanged: (value) {
                  final nextType = value.first;
                  onChanged(exercise.copyWith(targetType: nextType));
                  setCtrl(
                    targetKey,
                    nextType == 'time'
                        ? (exercise.targetSeconds == 0 ? '' : exercise.targetSeconds.toString())
                        : (exercise.targetReps == 0 ? '' : exercise.targetReps.toString()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              controller: targetController,
              decoration: InputDecoration(
                labelText: exercise.targetType == 'time' ? 'Secondes' : 'Répétitions',
                hintText: '0',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              onChanged: (value) {
                final numValue = int.tryParse(value) ?? 0;
                onChanged(exercise.copyWith(
                  targetReps: exercise.targetType == 'time' ? exercise.targetReps : numValue,
                  targetSeconds: exercise.targetType == 'time' ? numValue : exercise.targetSeconds,
                ));
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Charge',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: 'bodyweight', label: Text('PDC')),
                  ButtonSegment(value: 'weight', label: Text('Poids')),
                ],
                selected: {exercise.loadType},
                onSelectionChanged: (value) {
                  final nextType = value.first;
                  onChanged(exercise.copyWith(
                    loadType: nextType,
                    loadValue: nextType == 'bodyweight' ? 0 : exercise.loadValue,
                    loadMode: nextType == 'bodyweight' ? 'total' : exercise.loadMode,
                  ));
                  if (nextType == 'bodyweight') {
                    setCtrl(weightKey, '');
                  }
                },
              ),
            ),
            if (exercise.loadType == 'weight') ...[
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Poids (kg)',
                  hintText: '0',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                ),
                onChanged: (value) {
                  onChanged(exercise.copyWith(loadValue: double.tryParse(value) ?? 0));
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(value: 'total', label: Text('Total')),
                    ButtonSegment(value: 'per_hand', label: Text('Par main')),
                  ],
                  selected: {exercise.loadMode},
                  onSelectionChanged: (value) {
                    onChanged(exercise.copyWith(loadMode: value.first));
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _exercisePicker(
    BuildContext context,
    List<Exercise> exercises,
    Exercise selected, {
    required void Function(Exercise) onPicked,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: exercises.isEmpty
          ? null
          : () async {
              final picked = await _showExercisePicker(context, exercises, selected);
              if (picked != null) {
                onPicked(picked);
              }
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Exercice',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected.name.isEmpty ? 'Sélectionner un exercice' : selected.name,
                style: TextStyle(
                  color: selected.name.isEmpty ? const Color(0xFF94A3B8) : null,
                ),
              ),
            ),
            const Icon(Icons.search),
          ],
        ),
      ),
    );
  }

  Future<Exercise?> _showExercisePicker(
    BuildContext context,
    List<Exercise> exercises,
    Exercise selected,
  ) {
    final controller = TextEditingController();
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = controller.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? exercises
                : exercises.where((e) => e.name.toLowerCase().contains(query)).toList();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sélectionner un exercice', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Rechercher',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final exercise = filtered[index];
                          final isSelected = exercise.id == selected.id;
                          return ListTile(
                            title: Text(exercise.name),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Color(0xFF2563EB))
                                : null,
                            onTap: () => Navigator.of(context).pop(exercise),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  SessionGroup _cloneGroup(SessionGroup group) {
    return SessionGroup(
      orderIndex: group.orderIndex,
      rounds: group.rounds,
      restBetweenRoundsSeconds: group.restBetweenRoundsSeconds,
      exercises: group.exercises.map((e) => e.copyWith()).toList(),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la séance est obligatoire.')),
      );
      return;
    }
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un bloc.')),
      );
      return;
    }
    for (final group in _groups) {
      if (group.exercises.any((e) => e.exerciseId.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chaque exercice doit être sélectionné.')),
        );
        return;
      }
    }

    final normalizedGroups = <SessionGroup>[];
    for (var i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final exercises = <SessionExerciseConfig>[];
      for (var j = 0; j < group.exercises.length; j++) {
        final exercise = group.exercises[j];
        exercises.add(exercise.copyWith(orderIndex: j));
      }
      normalizedGroups.add(SessionGroup(
        orderIndex: i,
        rounds: group.rounds,
        restBetweenRoundsSeconds: group.restBetweenRoundsSeconds,
        exercises: exercises,
      ));
    }

    final session = TrainingSessionTemplate(
      id: widget.sessionId ?? _uuid.v4(),
      name: _nameController.text.trim().isEmpty ? 'Séance' : _nameController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      groups: normalizedGroups,
    );

    await ref.read(appDataProvider.notifier).saveSession(session);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

extension on SessionExerciseConfig {
  SessionExerciseConfig copyWith({
    String? exerciseId,
    int? orderIndex,
    String? targetType,
    int? targetReps,
    int? targetSeconds,
    int? restSeconds,
    String? loadType,
    double? loadValue,
    String? loadMode,
    String? notes,
    Exercise? exercise,
  }) {
    return SessionExerciseConfig(
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      targetType: targetType ?? this.targetType,
      targetReps: targetReps ?? this.targetReps,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      loadType: loadType ?? this.loadType,
      loadValue: loadValue ?? this.loadValue,
      loadMode: loadMode ?? this.loadMode,
      notes: notes ?? this.notes,
      exercise: exercise ?? this.exercise,
    );
  }
}
