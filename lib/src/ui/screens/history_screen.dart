import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(appStateProvider).sessions;
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (sessions.isEmpty)
              Text(
                'Aucune seance terminee.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final session in sessions.reversed)
              Card(
                child: ListTile(
                  title: Text(session.name),
                  subtitle: Text(
                    'Date: ${session.dateIso.isEmpty ? '-' : formatter.format(DateTime.parse(session.dateIso))}\n'
                    'Duree: ${session.durationMinutes} min',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
