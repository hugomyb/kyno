import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/profile.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/app_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _startTimerController;
  bool _didInitFromProfile = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appDataProvider).profile;
    _heightController = TextEditingController(
      text: profile.heightCm == 0 ? '' : profile.heightCm.toString(),
    );
    _weightController = TextEditingController(
      text: profile.weightKg == 0 ? '' : profile.weightKg.toString(),
    );
    _startTimerController = TextEditingController(
      text: profile.startTimerSeconds.toString(),
    );
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _startTimerController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _startTimerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appDataProvider).profile;
    final history = ref.watch(appDataProvider).weightEntries;

    if (!_didInitFromProfile && profile.id != 'profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _heightController.text = profile.heightCm == 0 ? '' : profile.heightCm.toString();
        _weightController.text = profile.weightKg == 0 ? '' : profile.weightKg.toString();
        _startTimerController.text = profile.startTimerSeconds.toString();
        setState(() {
          _didInitFromProfile = true;
          _hasChanges = false;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _hasChanges
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
              ),
            )
          : null,
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
                const SizedBox(height: 16),
                _settingsCard(context),
                const SizedBox(height: 80),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Se deconnecter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
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
            'Paramètres',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _inputBlock(
            label: 'Timer de départ (s)',
            controller: _startTimerController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _weightChartCard(BuildContext context, List<WeightEntry> history) {
    final sorted = [...history]..sort((a, b) => a.dateIso.compareTo(b.dateIso));
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
          if (sorted.isEmpty)
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
                          if (index < 0 || index >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.tryParse(sorted[index].dateIso);
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
                        for (var i = 0; i < sorted.length; i++)
                          FlSpot(i.toDouble(), sorted[i].weightKg),
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

  Future<void> _saveProfile() async {
    final notifier = ref.read(appDataProvider.notifier);
    final profile = ref.read(appDataProvider).profile;

    final height = int.tryParse(_heightController.text.trim()) ?? profile.heightCm;
    final weight = double.tryParse(_weightController.text.trim()) ?? profile.weightKg;
    final startTimerSeconds =
        int.tryParse(_startTimerController.text.trim()) ?? profile.startTimerSeconds;

    final updated = profile.copyWith(
      heightCm: height,
      weightKg: weight,
      startTimerSeconds: startTimerSeconds.clamp(0, 60),
    );

    setState(() => _isSaving = true);
    try {
      await notifier.updateProfile(updated);
      if (weight > 0) {
        await notifier.addWeightEntry(weight);
      }
      if (!mounted) return;
      setState(() => _hasChanges = false);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('FormatException')
          ? 'Réponse invalide du serveur. Vérifie l’API.'
          : 'Impossible de sauvegarder le profil.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  void _onFieldChanged() {
    _syncDirtyFlag(ref.read(appDataProvider).profile);
  }

  void _syncDirtyFlag(Profile profile) {
    if (!_didInitFromProfile) return;
    final height = int.tryParse(_heightController.text.trim()) ?? profile.heightCm;
    final weight = double.tryParse(_weightController.text.trim()) ?? profile.weightKg;
    final startTimerSeconds =
        int.tryParse(_startTimerController.text.trim()) ?? profile.startTimerSeconds;
    final hasChanges = height != profile.heightCm ||
        weight != profile.weightKg ||
        startTimerSeconds.clamp(0, 60) != profile.startTimerSeconds;
    if (hasChanges != _hasChanges && mounted) {
      setState(() => _hasChanges = hasChanges);
    }
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
