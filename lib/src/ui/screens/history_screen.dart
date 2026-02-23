import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_data_provider.dart';
import '../widgets/app_background.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(appDataProvider).workoutSessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (sessions.isEmpty)
                  const Text('Aucune séance terminée.')
                else
                  for (final session in sessions.reversed)
                    Card(
                      child: ListTile(
                        title: Text(session.name),
                        subtitle: Text(session.dateIso),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
