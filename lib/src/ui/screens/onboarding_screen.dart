import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../providers/app_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _height;
  late TextEditingController _weight;
  String _armLength = 'normal';
  String _femurLength = 'normal';
  String _goal = 'hypertrophy';
  final _limitations = <String>{};
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appStateProvider).profile;
    _name = TextEditingController(text: profile.name);
    _height = TextEditingController(text: profile.heightCm == 0 ? '' : profile.heightCm.toString());
    _weight = TextEditingController(text: profile.weightKg == 0 ? '' : profile.weightKg.toString());
    _armLength = profile.armLength;
    _femurLength = profile.femurLength;
    _goal = profile.goal;
    _limitations.addAll(profile.limitations);
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding IA + profil'),
        leading: BackButton(
          onPressed: () => _handleBack(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 1) {
                setState(() => _currentStep += 1);
                return;
              }
              final profile = Profile(
                id: 'profile',
                name: _name.text.trim(),
                heightCm: int.tryParse(_height.text.trim()) ?? 0,
                weightKg: double.tryParse(_weight.text.trim()) ?? 0,
                armLength: _armLength,
                femurLength: _femurLength,
                limitations: _limitations.toList(),
                goal: _goal,
                weightHistory: <WeightEntry>[],
              );
              final notifier = ref.read(appStateProvider.notifier);
              notifier.updateProfile(profile);
              notifier.save();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            onStepCancel: () {
              if (_currentStep == 0) return;
              setState(() => _currentStep -= 1);
            },
            controlsBuilder: (context, details) {
              return Row(
                children: [
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 1 ? 'Enregistrer' : 'Continuer'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Retour'),
                  ),
                ],
              );
            },
            steps: [
              Step(
                title: const Text('Profil'),
                content: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Taille (cm)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Poids (kg)'),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Morphologie'),
                content: Column(
                  children: [
                    DropdownMenu<String>(
                      initialSelection: _armLength,
                      label: const Text('Longueur des bras'),
                      onSelected: (value) => setState(() => _armLength = value ?? 'normal'),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'short', label: 'Bras courts'),
                        DropdownMenuEntry(value: 'normal', label: 'Bras normaux'),
                        DropdownMenuEntry(value: 'long', label: 'Bras longs'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      initialSelection: _femurLength,
                      label: const Text('Longueur des femurs'),
                      onSelected: (value) => setState(() => _femurLength = value ?? 'normal'),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'short', label: 'Femurs courts'),
                        DropdownMenuEntry(value: 'normal', label: 'Femurs normaux'),
                        DropdownMenuEntry(value: 'long', label: 'Femurs longs'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      initialSelection: _goal,
                      label: const Text('Objectif'),
                      onSelected: (value) => setState(() => _goal = value ?? 'hypertrophy'),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'force', label: 'Force'),
                        DropdownMenuEntry(value: 'hypertrophy', label: 'Hypertrophie'),
                        DropdownMenuEntry(value: 'endurance', label: 'Endurance'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Limitations / douleurs',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        _flagChip('Epaule'),
                        _flagChip('Coude'),
                        _flagChip('Genou'),
                        _flagChip('Dos'),
                        _flagChip('Poignet'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  Widget _flagChip(String label) {
    final selected = _limitations.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _limitations.add(label);
          } else {
            _limitations.remove(label);
          }
        });
      },
    );
  }
}
