import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notifications_types.dart';
import 'service_providers.dart';

class PushNotificationsState {
  const PushNotificationsState({
    required this.supported,
    required this.isEnabled,
    required this.permission,
    this.supportReason,
    this.isLoading = false,
    this.error,
  });

  final bool supported;
  final bool isEnabled;
  final PushPermission permission;
  final String? supportReason;
  final bool isLoading;
  final String? error;

  PushNotificationsState copyWith({
    bool? supported,
    bool? isEnabled,
    PushPermission? permission,
    String? supportReason,
    bool? isLoading,
    String? error,
  }) {
    return PushNotificationsState(
      supported: supported ?? this.supported,
      isEnabled: isEnabled ?? this.isEnabled,
      permission: permission ?? this.permission,
      supportReason: supportReason ?? this.supportReason,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory PushNotificationsState.initial() {
    return const PushNotificationsState(
      supported: false,
      isEnabled: false,
      permission: PushPermission.prompt,
      supportReason: null,
      isLoading: false,
      error: null,
    );
  }
}

class PushNotificationsNotifier extends Notifier<PushNotificationsState> {
  late final PushNotificationsService _service;

  @override
  PushNotificationsState build() {
    _service = ref.read(pushNotificationsServiceProvider);
    Future.microtask(refresh);
    return PushNotificationsState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final support = await _service.checkSupport();
      final permission = await _service.checkPermission();
      final enabled = support.isSupported ? await _service.isSubscribed() : false;
      state = state.copyWith(
        supported: support.isSupported,
        supportReason: support.reason,
        permission: permission,
        isEnabled: enabled,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les notifications push',
      );
    }
  }

  Future<void> toggle(bool enable) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (enable) {
        final success = await _service.enable();
        if (!success) {
          state = state.copyWith(
            isLoading: false,
            error: 'Autorisation refusée ou configuration manquante',
          );
          await refresh();
          return;
        }
      } else {
        await _service.disable();
      }
      await refresh();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise a jour des notifications',
      );
    }
  }
}

final pushNotificationsProvider = NotifierProvider<PushNotificationsNotifier, PushNotificationsState>(
  PushNotificationsNotifier.new,
);
