import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../providers/app_state_provider.dart';
import '../../services/program_import_service.dart';
import '../widgets/app_background.dart';
import '../widgets/soft_card.dart';

class ProgramImportScreen extends ConsumerStatefulWidget {
  const ProgramImportScreen({super.key});

  @override
  ConsumerState<ProgramImportScreen> createState() => _ProgramImportScreenState();
}

class _ProgramImportScreenState extends ConsumerState<ProgramImportScreen> {
  bool _loading = false;
  String? _error;
  String? _filename;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer JSON')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Importe un fichier JSON au format programme.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (_filename != null)
                      Text(
                        _filename!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loading ? null : _importFromFile,
                      icon: const Icon(Icons.upload),
                      label: Text(_loading ? 'Import...' : 'Importer un fichier'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _filename = result.files.first.name;
    });
    try {
      final jsonString = utf8.decode(bytes);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = ProgramImportService().fromJson(jsonMap);
      final notifier = ref.read(appStateProvider.notifier);
      notifier.updateProgram(data.program);
      final incomingProfile = data.profile;
      if (incomingProfile != null) {
        final current = ref.read(appStateProvider).profile;
        final merged = current.copyWith(
          heightCm: incomingProfile.heightCm == 0
              ? current.heightCm
              : incomingProfile.heightCm,
          weightKg: incomingProfile.weightKg == 0
              ? current.weightKg
              : incomingProfile.weightKg,
          goal: incomingProfile.goal.isEmpty ? current.goal : incomingProfile.goal,
        );
        final shouldAddWeight = incomingProfile.weightKg > 0;
        if (shouldAddWeight) {
          final updatedHistory = _upsertWeightForToday(
            current.weightHistory,
            incomingProfile.weightKg,
          );
          notifier.updateProfile(
            merged.copyWith(weightHistory: updatedHistory),
          );
        } else {
          notifier.updateProfile(merged);
        }
      }
      await notifier.save();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/');
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Erreur import: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
}
