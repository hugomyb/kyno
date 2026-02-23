import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/program.dart';
import '../../models/session.dart';
import '../../models/session_template.dart';
import '../../providers/app_data_provider.dart';
import '../widgets/app_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appDataProvider);
    final program = state.program;
    final todayDay = DateTime.now().weekday;
    final day = program.days.firstWhere(
      (d) => d.dayOfWeek == todayDay,
      orElse: () => ProgramDay(
        id: null,
        dayOfWeek: todayDay,
        sessionId: null,
        orderIndex: 0,
      ),
    );
    final sessionId = day.sessionId;
    final session = sessionId == null
        ? TrainingSessionTemplate(
            id: '',
            name: '',
            notes: null,
            groups: const [],
          )
        : state.sessions.firstWhere(
            (s) => s.id == sessionId,
            orElse: () => TrainingSessionTemplate(
              id: '',
              name: '',
              notes: null,
              groups: const [],
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _todayCard(context, session),
                const SizedBox(height: 16),
                _sessionPicker(context, state.sessions),
                const SizedBox(height: 16),
                _quickActions(context),
                const SizedBox(height: 16),
                _historyCard(context, state.workoutSessions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayCard(BuildContext context, TrainingSessionTemplate session) {
    if (session.id.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text('Aucune séance assignée pour aujourd’hui.'),
      );
    }

    final exerciseCount = session.groups
        .expand((group) => group.exercises)
        .length;

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
            'Séance du jour',
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
              _chip('${session.groups.length} blocs'),
              const SizedBox(width: 8),
              _chip('$exerciseCount exos'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/workout?sessionId=${session.id}'),
              child: const Text('Démarrer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accès rapide', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  label: 'Séances',
                  icon: Icons.list_alt,
                  onTap: () => context.push('/sessions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  context,
                  label: 'Exercices',
                  icon: Icons.fitness_center,
                  onTap: () => context.push('/exercises'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              context,
              label: 'Programme',
              icon: Icons.calendar_month,
              onTap: () => context.push('/program'),
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return SizedBox(
      height: 60,
      width: fullWidth ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
            'Séance en cours',
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
          _chip(label, color: activeWorkout.paused ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _sessionPicker(BuildContext context, List<TrainingSessionTemplate> sessions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisir une autre séance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            const Text('Aucune séance disponible.')
          else
            for (final session in sessions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.go('/workout?sessionId=${session.id}'),
                      child: const Text('Démarrer'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _historyCard(BuildContext context, List<WorkoutSessionLog> sessions) {
    final sorted = [...sessions]
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historique', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            const Text('Aucune séance terminée.')
          else
            for (final session in sorted.take(10))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _chip('${session.durationMinutes} min', color: const Color(0xFF0EA5E9)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(session.dateIso),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _chip(String label, {Color color = const Color(0xFF2563EB)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
