import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/program.dart';
import '../../models/session.dart';
import '../../models/session_template.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/notifications_provider.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appDataProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final profile = state.profile;
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

    final userName = profile.name.isNotEmpty ? profile.name : 'Athlète';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Accueil',
        subtitle: 'Bienvenue $userName',
        actions: [
          _buildNotificationButton(context, notificationsState.unreadCount),
        ],
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _todayCard(context, session),
                const SizedBox(height: 24),
                _sessionPicker(context, state.sessions),
                const SizedBox(height: 24),
                _quickActions(context),
                const SizedBox(height: 24),
                _historyCard(context, state.workoutSessions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayCard(BuildContext context, TrainingSessionTemplate session) {
    final colors = context.themeColors;

    if (session.id.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: colors.cardShadow,
        ),
        child: const Text('Aucune séance assignée pour aujourd’hui.'),
      );
    }

    final exerciseCount = session.groups
        .expand((group) => group.exercises)
        .length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF1E40AF).withValues(alpha: 0.1),
                ]
              : [
                  const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  const Color(0xFF60A5FA).withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
              : const Color(0xFF3B82F6).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: colors.isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.today,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Séance du jour',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            session.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('${session.groups.length} blocs'),
              const SizedBox(width: 8),
              _chip('$exerciseCount exos'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/workout?sessionId=${session.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Démarrer',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final colors = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Accès rapide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                context,
                label: 'Séances',
                icon: Icons.list_alt,
                color: const Color(0xFF3B82F6),
                onTap: () => context.push('/sessions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                context,
                label: 'Exercices',
                icon: Icons.fitness_center,
                color: const Color(0xFF10B981),
                onTap: () => context.push('/exercises'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.themeColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeCard(BuildContext context, ActiveWorkout activeWorkout) {
    final colors = context.themeColors;
    final sessionName = activeWorkout.session.name;
    final label = activeWorkout.paused ? 'En pause' : 'En cours';
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackgroundAlt,
        borderRadius: BorderRadius.circular(24),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Séance en cours',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _chip(label, color: activeWorkout.paused ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _sessionPicker(BuildContext context, List<TrainingSessionTemplate> sessions) {
    final colors = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Choisir une autre séance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                'Aucune séance disponible.',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          ...sessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/workout?sessionId=${session.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: colors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: colors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              session.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _historyCard(BuildContext context, List<WorkoutSessionLog> sessions) {
    final colors = context.themeColors;
    final sorted = [...sessions]
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Historique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sorted.isEmpty)
                Center(
                  child: Text(
                    'Aucune séance terminée.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              else
                for (final session in sorted.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0EA5E9),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(session.dateIso),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _chip('${session.durationMinutes} min', color: const Color(0xFF0EA5E9)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _chip(String label, {Color? color}) {
    return Builder(
      builder: (context) {
        final chipColor = color ?? context.themeColors.primary;
        final colors = context.themeColors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.chipBackground(chipColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: chipColor),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton(BuildContext context, int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.go('/notifications'),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
