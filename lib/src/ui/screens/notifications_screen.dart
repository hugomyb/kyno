import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification.dart';
import '../../providers/friends_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/session_sharing_provider.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeColors;
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Notifications',
                  subtitle: '${notificationsState.unreadCount} non lue(s)',
                  showBackButton: true,
                  onBackPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  actions: [
                    if (notificationsState.unreadCount > 0)
                      TextButton(
                        onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
                        child: Text(
                          'Tout lire',
                          style: TextStyle(color: colors.primary),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(notificationsProvider.notifier).loadAll(),
                    child: notificationsState.notifications.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: notificationsState.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notificationsState.notifications[index];
                              return _buildNotificationCard(context, ref, colors, notification);
                            },
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

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez aucune notification pour le moment',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    ThemeColors colors,
    AppNotification notification,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.read ? colors.cardBackground : colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.read
              ? colors.border.withValues(alpha: 0.5)
              : colors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(context, ref, notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getNotificationIcon(notification.type),
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'session_shared':
        return Icons.share;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Mark as read
    if (!notification.read) {
      await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Handle based on type
    if (notification.type == 'friend_request') {
      final requestId = notification.data?['friend_request_id']?.toString();
      if (requestId != null && context.mounted) {
        await _showFriendRequestDialog(context, ref, requestId, notification.id);
      }
    } else if (notification.type == 'session_shared') {
      final sharedSessionId = notification.data?['shared_session_id']?.toString();
      if (sharedSessionId != null && context.mounted) {
        await _showSharedSessionDialog(context, ref, sharedSessionId, notification.id);
      }
    }
  }

  Future<void> _showFriendRequestDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String notificationId,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande d\'ami'),
        content: const Text('Que voulez-vous faire avec cette demande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'reject'),
            child: const Text('Refuser', style: TextStyle(color: Color(0xFFEF4444))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'accept'),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (action == 'accept') {
      try {
        await ref.read(friendsProvider.notifier).acceptRequest(requestId);
        // Delete notification after accepting
        await ref.read(notificationsProvider.notifier).deleteNotification(notificationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ami ajouté !'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showError(context, _extractErrorMessage(e.toString()));
        }
      }
    } else if (action == 'reject') {
      try {
        await ref.read(friendsProvider.notifier).rejectRequest(requestId);
        // Delete notification after rejecting
        await ref.read(notificationsProvider.notifier).deleteNotification(notificationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande refusée')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showError(context, _extractErrorMessage(e.toString()));
        }
      }
    }
  }

  Future<void> _showSharedSessionDialog(
    BuildContext context,
    WidgetRef ref,
    String sharedSessionId,
    String notificationId,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Séance partagée'),
        content: const Text('Voulez-vous ajouter cette séance à votre liste ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'reject'),
            child: const Text('Refuser', style: TextStyle(color: Color(0xFFEF4444))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'accept'),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (action == 'accept') {
      try {
        await ref.read(sessionSharingProvider.notifier).acceptShare(sharedSessionId);
        // Delete notification after accepting
        await ref.read(notificationsProvider.notifier).deleteNotification(notificationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Séance ajoutée à vos séances !'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showError(context, _extractErrorMessage(e.toString()));
        }
      }
    } else if (action == 'reject') {
      try {
        await ref.read(sessionSharingProvider.notifier).rejectShare(sharedSessionId);
        // Delete notification after rejecting
        await ref.read(notificationsProvider.notifier).deleteNotification(notificationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Séance refusée')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showError(context, _extractErrorMessage(e.toString()));
        }
      }
    }
  }

  String _extractErrorMessage(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    final apiExceptionMatch = RegExp(r'ApiException\(\d+\): (.+)').firstMatch(error);
    if (apiExceptionMatch != null) {
      return apiExceptionMatch.group(1) ?? error;
    }
    return error;
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
