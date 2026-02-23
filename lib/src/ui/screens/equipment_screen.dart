import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_data_provider.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipment = ref.watch(appDataProvider).equipment;
    final notifier = ref.read(appDataProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materiel'),
        leading: BackButton(onPressed: () => _handleBack(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _showAddSheet(context, notifier),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter materiel'),
            ),
            const SizedBox(height: 12),
            if (equipment.isEmpty)
              Text(
                'Aucun materiel enregistre.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final item in equipment)
              Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.notes),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      notifier.removeEquipment(item.id);
                    },
                  ),
                ),
              ),
          ],
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

  Future<void> _showAddSheet(
    BuildContext context,
    AppDataNotifier notifier,
  ) async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau materiel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        notifier.addEquipment(
                          nameController.text.trim(),
                          notesController.text.trim(),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Ajouter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
