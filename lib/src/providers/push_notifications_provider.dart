import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notifications_types.dart';
import 'service_providers.dart';

class PushNotificationsState {
  const PushNotificationsState({
    required this.supported,
    required this.isEnabled,
    required this.permission,
    this.supportReason,
    this.diagnostics,
    this.isLoading = false,
    this.error,
  });

  final bool supported;
  final bool isEnabled;
  final PushPermission permission;
  final String? supportReason;
  final PushDiagnostics? diagnostics;
  final bool isLoading;
  final String? error;

  PushNotificationsState copyWith({
    bool? supported,
    bool? isEnabled,
    PushPermission? permission,
    String? supportReason,
    PushDiagnostics? diagnostics,
    bool? isLoading,
    String? error,
  }) {
    return PushNotificationsState(
      supported: supported ?? this.supported,
      isEnabled: isEnabled ?? this.isEnabled,
      permission: permission ?? this.permission,
      supportReason: supportReason ?? this.supportReason,
      diagnostics: diagnostics ?? this.diagnostics,
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
      diagnostics: null,
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
      PushDiagnostics? diagnostics;
      try {
        diagnostics = await _service.buildDiagnostics();
      } catch (_) {}

      final support = await _service.checkSupport();
      if (!support.isSupported) {
        state = state.copyWith(
          supported: false,
          supportReason: support.reason,
          permission: PushPermission.prompt,
          isEnabled: false,
          diagnostics: diagnostics,
          isLoading: false,
        );
        return;
      }

      final permission = await _service.checkPermission();
      final enabled = await _service.isSubscribed();
      state = state.copyWith(
        supported: true,
        supportReason: support.reason,
        permission: permission,
        isEnabled: enabled,
        diagnostics: diagnostics,
        isLoading: false,
      );
    } catch (e) {
      final message = 'Impossible de charger les notifications push: $e';
      state = state.copyWith(
        isLoading: false,
        diagnostics: state.diagnostics,
        error: message,
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
