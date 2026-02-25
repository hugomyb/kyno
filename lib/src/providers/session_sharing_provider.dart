import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shared_session.dart';
import '../services/api_service.dart';
import 'app_data_provider.dart';
import 'service_providers.dart';

class SessionSharingState {
  SessionSharingState({
    required this.sharedSessions,
    required this.isLoading,
  });

  final List<SharedSession> sharedSessions;
  final bool isLoading;

  SessionSharingState copyWith({
    List<SharedSession>? sharedSessions,
    bool? isLoading,
  }) {
    return SessionSharingState(
      sharedSessions: sharedSessions ?? this.sharedSessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory SessionSharingState.initial() {
    return SessionSharingState(
      sharedSessions: [],
      isLoading: false,
    );
  }
}

class SessionSharingNotifier extends Notifier<SessionSharingState> {
  late final ApiService _api;
  Timer? _pollingTimer;

  @override
  SessionSharingState build() {
    _api = ref.read(apiServiceProvider);
    // Load data asynchronously after initialization
    Future.microtask(() => loadAll());
    // Start polling every 15 seconds
    _startPolling();
    // Cancel timer when provider is disposed
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return SessionSharingState.initial();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadAll();
    });
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final shares = await _api.fetchSharedSessions();
      state = SessionSharingState(
        sharedSessions: shares,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Don't rethrow to avoid breaking the polling
      // Silent fail for background updates
    }
  }

  Future<void> shareSession(String sessionId, String friendId) async {
    await _api.shareSession(sessionId, friendId);
  }

  Future<void> acceptShare(String sharedSessionId) async {
    await _api.acceptSharedSession(sharedSessionId);
    // Refresh app data to include the new session
    await ref.read(appDataProvider.notifier).refreshSessions();
    await loadAll();
  }

  Future<void> rejectShare(String sharedSessionId) async {
    await _api.rejectSharedSession(sharedSessionId);
    await loadAll();
  }
}

final sessionSharingProvider = NotifierProvider<SessionSharingNotifier, SessionSharingState>(
  SessionSharingNotifier.new,
);

