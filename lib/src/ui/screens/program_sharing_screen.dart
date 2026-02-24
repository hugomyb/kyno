import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/service_providers.dart';
import '../widgets/app_background.dart';
import '../widgets/soft_card.dart';

class ProgramSharingScreen extends ConsumerStatefulWidget {
  const ProgramSharingScreen({super.key});

  @override
  ConsumerState<ProgramSharingScreen> createState() => _ProgramSharingScreenState();
}

class _ProgramSharingScreenState extends ConsumerState<ProgramSharingScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final users = await api.fetchUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des utilisateurs';
        _loading = false;
      });
    }
  }

  Future<void> _copyProgram(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copier le programme'),
        content: Text(
          'Voulez-vous copier le programme de $userName ?\n\n'
          'Cela remplacera votre programme actuel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Copier'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(apiServiceProvider);
      await api.copyUserProgram(userId);
      
      // Refresh program data
      await ref.read(appDataProvider.notifier).refreshProgram();
      await ref.read(appDataProvider.notifier).refreshSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programme copié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Partage de programmes',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_error!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _loadUsers,
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            )
                          : _users.isEmpty
                              ? const Center(child: Text('Aucun utilisateur trouvé'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _userCard(user, theme),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(User user, ThemeData theme) {
    return SoftCard(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3B82F6),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _copyProgram(user.id, user.name),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}

