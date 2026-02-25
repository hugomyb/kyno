import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend.dart';
import '../../providers/friends_provider.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _emailController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final friendsState = ref.watch(friendsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Amis',
                  subtitle: '${friendsState.friends.length} ami(s)',
                  showBackButton: true,
                  onBackPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(friendsProvider.notifier).loadAll(),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSearchSection(colors),
                        const SizedBox(height: 24),
                        if (friendsState.friendRequests.isNotEmpty) ...[
                          _buildRequestsSection(colors, friendsState.friendRequests),
                          const SizedBox(height: 24),
                        ],
                        _buildFriendsSection(colors, friendsState.friends),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajouter un ami',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Email de votre ami',
              hintStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: colors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
            style: TextStyle(color: colors.textPrimary),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _searching ? null : _searchAndSendRequest,
              child: _searching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Rechercher et envoyer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(ThemeColors colors, List<FriendRequest> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Demandes en attente (${requests.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...requests.map((request) => _buildRequestCard(colors, request)),
      ],
    );
  }

  Widget _buildRequestCard(ThemeColors colors, FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.sender.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.sender.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _acceptRequest(request.id),
            icon: const Icon(Icons.check, color: Color(0xFF10B981)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _rejectRequest(request.id),
            icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection(ThemeColors colors, List<Friend> friends) {
    if (friends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
        ),
        child: Center(
          child: Text(
            'Aucun ami pour le moment',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes amis (${friends.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...friends.map((friend) => _buildFriendCard(colors, friend)),
      ],
    );
  }

  Widget _buildFriendCard(ThemeColors colors, Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFriend(friend),
            icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndSendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Veuillez entrer un email');
      return;
    }

    setState(() => _searching = true);
    try {
      await ref.read(friendsProvider.notifier).searchAndSendRequest(email);
      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Demande d\'ami envoyée !'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      _showError(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await ref.read(friendsProvider.notifier).acceptRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ami ajouté !'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      _showError(_extractErrorMessage(e.toString()));
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await ref.read(friendsProvider.notifier).rejectRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande refusée')),
        );
      }
    } catch (e) {
      _showError(_extractErrorMessage(e.toString()));
    }
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet ami ?'),
        content: Text('Voulez-vous vraiment retirer ${friend.name} de vos amis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(friendsProvider.notifier).removeFriend(friend.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ami retiré de votre liste')),
          );
        }
      } catch (e) {
        _showError(_extractErrorMessage(e.toString()));
      }
    }
  }

  String _extractErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    // Remove "ApiException(xxx): " prefix if present
    final apiExceptionMatch = RegExp(r'ApiException\(\d+\): (.+)').firstMatch(error);
    if (apiExceptionMatch != null) {
      return apiExceptionMatch.group(1) ?? error;
    }
    return error;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

