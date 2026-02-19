import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../services/file_download_stub.dart'
    if (dart.library.html) '../../services/file_download_web.dart';

class ExportImportScreen extends ConsumerStatefulWidget {
  const ExportImportScreen({super.key});

  @override
  ConsumerState<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends ConsumerState<ExportImportScreen> {
  bool _merge = true;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final exportService = ref.read(exportServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export / Import'),
        leading: BackButton(onPressed: () => _handleBack(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () {
                final filename = 'muscu_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
                final json = exportService.exportToJson(state);
                try {
                  downloadJson(filename, json);
                  setState(() => _message = 'Export pret: $filename');
                } catch (error) {
                  setState(() => _message = 'Export indisponible: $error');
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Exporter JSON'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Fusion intelligente'),
              subtitle: const Text('Si desactive, remplacement complet.'),
              value: _merge,
              onChanged: (value) => setState(() => _merge = value),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                  withData: true,
                );
                if (result == null || result.files.isEmpty) return;
                final bytes = result.files.first.bytes;
                if (bytes == null) return;
                final jsonString = String.fromCharCodes(bytes);

                try {
                  final incoming = exportService.importFromJson(jsonString);
                  final notifier = ref.read(appStateProvider.notifier);
                  if (_merge) {
                    final merged = exportService.mergeState(
                      current: state,
                      incoming: incoming,
                    );
                    notifier.replaceAll(merged: merged);
                  } else {
                    notifier.replaceAll(merged: incoming);
                  }
                  notifier.save();
                  setState(() => _message = 'Import reussi');
                } catch (error) {
                  setState(() => _message = 'Import echoue: $error');
                }
              },
              icon: const Icon(Icons.upload),
              label: const Text('Importer JSON'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
}
