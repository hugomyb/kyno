import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

class NotificationsState {
  NotificationsState({
    required this.notifications,
    required this.unreadCount,
    required this.isLoading,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory NotificationsState.initial() {
    return NotificationsState(
      notifications: [],
      unreadCount: 0,
      isLoading: false,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  late final ApiService _api;
  Timer? _pollingTimer;

  @override
  NotificationsState build() {
    _api = ref.read(apiServiceProvider);
    // Load data asynchronously after initialization
    Future.microtask(() => loadAll());
    // Start polling every 10 seconds
    _startPolling();
    // Cancel timer when provider is disposed
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return NotificationsState.initial();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadAll();
    });
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _api.fetchNotifications(),
        _api.fetchUnreadNotificationsCount(),
      ]);
      state = NotificationsState(
        notifications: results[0] as List<AppNotification>,
        unreadCount: results[1] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Don't rethrow to avoid breaking the polling
      // Silent fail for background updates
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.markNotificationAsRead(notificationId);
    await loadAll();
  }

  Future<void> markAllAsRead() async {
    await _api.markAllNotificationsAsRead();
    await loadAll();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _api.deleteNotification(notificationId);
    await loadAll();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

