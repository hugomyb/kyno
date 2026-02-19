import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/profile.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/soft_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appStateProvider).profile;
    _heightController = TextEditingController(
      text: profile.heightCm == 0 ? '' : profile.heightCm.toString(),
    );
    _weightController = TextEditingController(
      text: profile.weightKg == 0 ? '' : profile.weightKg.toString(),
    );
    _goalController = TextEditingController(text: profile.goal);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appStateProvider).profile;
    final history = _sortedHistory(profile.weightHistory);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _profileCard(context, profile),
                const SizedBox(height: 16),
                _weightChartCard(context, history),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context, Profile profile) {
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
            'Profil',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _inputBlock(
                  label: 'Taille (cm)',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputBlock(
                  label: 'Poids (kg)',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _inputBlock(
            label: 'Objectif',
            controller: _goalController,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveProfile,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightChartCard(BuildContext context, List<WeightEntry> history) {
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
            'Courbe de poids',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Text(
              'Aucune mesure enregistree.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
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
                          if (index < 0 || index >= history.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.tryParse(history[index].dateIso);
                          final label =
                              date == null ? '' : DateFormat('dd/MM').format(date);
                          return Text(label, style: const TextStyle(fontSize: 10));
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
                        for (var i = 0; i < history.length; i++)
                          FlSpot(i.toDouble(), history[i].weightKg),
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

  void _saveProfile() {
    final notifier = ref.read(appStateProvider.notifier);
    final profile = ref.read(appStateProvider).profile;

    final height = int.tryParse(_heightController.text.trim()) ?? profile.heightCm;
    final weight = double.tryParse(_weightController.text.trim()) ?? profile.weightKg;
    final goal = _goalController.text.trim().isEmpty ? profile.goal : _goalController.text.trim();

    var updated = profile.copyWith(
      heightCm: height,
      weightKg: weight,
      goal: goal,
    );

    if (weight > 0) {
      updated = updated.copyWith(
        weightHistory: _upsertWeightForToday(profile.weightHistory, weight),
      );
    }

    notifier.updateProfile(updated);
    notifier.save();
  }

  List<WeightEntry> _sortedHistory(List<WeightEntry> history) {
    final list = [...history];
    list.sort((a, b) => a.dateIso.compareTo(b.dateIso));
    return list;
  }

  List<WeightEntry> _upsertWeightForToday(
    List<WeightEntry> history,
    double weight,
  ) {
    final today = DateTime.now();
    final updated = [...history];
    final index = updated.indexWhere((entry) {
      final date = DateTime.tryParse(entry.dateIso);
      if (date == null) return false;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    });
    if (index >= 0) {
      updated[index] = WeightEntry(
        dateIso: DateTime.now().toIso8601String(),
        weightKg: weight,
      );
      return updated;
    }
    updated.add(
      WeightEntry(
        dateIso: DateTime.now().toIso8601String(),
        weightKg: weight,
      ),
    );
    return updated;
  }

  Widget _inputBlock({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F5FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
