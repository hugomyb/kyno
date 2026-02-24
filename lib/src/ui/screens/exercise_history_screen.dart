import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/session.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/number_format.dart';
import '../widgets/app_background.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final workoutSessions = ref.watch(appDataProvider).workoutSessions;

    // Filter sessions that contain this exercise
    final relevantSessions = workoutSessions.where((session) {
      return session.exerciseLogs.any((log) => log.exerciseId == exerciseId);
    }).toList()
      ..sort((a, b) => a.dateIso.compareTo(b.dateIso));

    // Extract data for chart
    final chartData = _extractChartData(relevantSessions);

    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: relevantSessions.isEmpty
                ? Center(
                    child: Text(
                      'Aucun historique pour cet exercice',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProgressionChart(context, chartData, isDark),
                      const SizedBox(height: 16),
                      _buildStatsCard(context, relevantSessions, isDark),
                      const SizedBox(height: 16),
                      _buildHistoryList(context, relevantSessions, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<_ChartPoint> _extractChartData(List<WorkoutSessionLog> sessions) {
    final points = <_ChartPoint>[];
    for (final session in sessions) {
      final exerciseLog = session.exerciseLogs.firstWhere(
        (log) => log.exerciseId == exerciseId,
        orElse: () => WorkoutExerciseLog(
          exerciseId: null,
          exerciseName: '',
          sets: [],
        ),
      );

      if (exerciseLog.sets.isNotEmpty) {
        // Calculate max weight for this session
        final maxWeight = exerciseLog.sets
            .map((set) => set.weight)
            .reduce((a, b) => a > b ? a : b);

        points.add(_ChartPoint(
          date: DateTime.tryParse(session.dateIso) ?? DateTime.now(),
          weight: maxWeight,
          sessionName: session.name,
        ));
      }
    }
    return points;
  }

  Widget _buildProgressionChart(
    BuildContext context,
    List<_ChartPoint> data,
    bool isDark,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression de charge',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final label = DateFormat('dd/MM').format(data[index].date);
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                    dotData: const FlDotData(show: true),
                    spots: [
                      for (var i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i].weight),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    List<WorkoutSessionLog> sessions,
    bool isDark,
  ) {
    final allSets = <WorkoutSetLog>[];
    for (final session in sessions) {
      final exerciseLog = session.exerciseLogs.firstWhere(
        (log) => log.exerciseId == exerciseId,
        orElse: () => WorkoutExerciseLog(
          exerciseId: null,
          exerciseName: '',
          sets: [],
        ),
      );
      allSets.addAll(exerciseLog.sets);
    }

    final maxWeight = allSets.isEmpty
        ? 0.0
        : allSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    final totalSets = allSets.length;
    final totalReps = allSets.map((s) => s.reps).reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Charge max', '${formatDecimalFr(maxWeight)}kg', isDark),
              _statItem('Total séries', '$totalSets', isDark),
              _statItem('Total reps', '$totalReps', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<WorkoutSessionLog> sessions,
    bool isDark,
  ) {
    final reversed = sessions.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique détaillé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
          ),
          const SizedBox(height: 12),
          for (final session in reversed) ...[
            _buildSessionItem(context, session, isDark),
            if (session != reversed.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionItem(
    BuildContext context,
    WorkoutSessionLog session,
    bool isDark,
  ) {
    final exerciseLog = session.exerciseLogs.firstWhere(
      (log) => log.exerciseId == exerciseId,
      orElse: () => WorkoutExerciseLog(
        exerciseId: null,
        exerciseName: '',
        sets: [],
      ),
    );

    final date = DateTime.tryParse(session.dateIso);
    final dateStr = date == null ? session.dateIso : DateFormat('dd/MM/yyyy').format(date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final set in exerciseLog.sets)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    set.weight > 0
                        ? '${formatDecimalFr(set.weight)}kg × ${set.reps}'
                        : '${set.reps} reps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  _ChartPoint({
    required this.date,
    required this.weight,
    required this.sessionName,
  });

  final DateTime date;
  final double weight;
  final String sessionName;
}


