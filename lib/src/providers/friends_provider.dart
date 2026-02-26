import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend.dart';
import '../services/api_service.dart';
import 'app_lifecycle_provider.dart';
import 'service_providers.dart';

class FriendsState {
  FriendsState({
    required this.friends,
    required this.friendRequests,
    required this.isLoading,
  });

  final List<Friend> friends;
  final List<FriendRequest> friendRequests;
  final bool isLoading;

  FriendsState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? friendRequests,
    bool? isLoading,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory FriendsState.initial() {
    return FriendsState(
      friends: [],
      friendRequests: [],
      isLoading: false,
    );
  }
}

class FriendsNotifier extends Notifier<FriendsState> {
  late final ApiService _api;
  Timer? _pollingTimer;

  @override
  FriendsState build() {
    _api = ref.read(apiServiceProvider);
    // Load data asynchronously after initialization
    Future.microtask(() => loadAll());
    // Start polling every 15 seconds
    _startPolling();
    ref.listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
      if (next == AppLifecycleState.resumed) {
        _startPolling();
        loadAll();
      } else {
        _stopPolling();
      }
    });
    // Cancel timer when provider is disposed
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return FriendsState.initial();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadAll();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _api.fetchFriends(),
        _api.fetchFriendRequests(),
      ]);
      state = FriendsState(
        friends: results[0] as List<Friend>,
        friendRequests: results[1] as List<FriendRequest>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Don't rethrow to avoid breaking the polling
      // Silent fail for background updates
    }
  }

  Future<void> searchAndSendRequest(String email) async {
    final user = await _api.searchUserByEmail(email);
    if (user == null) {
      throw Exception('Aucun utilisateur trouvé avec cet email');
    }

    // Check if already friends
    if (state.friends.any((f) => f.id == user.id)) {
      throw Exception('Vous êtes déjà ami avec cet utilisateur');
    }

    // Check if request already sent
    if (state.friendRequests.any((r) => r.sender.id == user.id)) {
      throw Exception('Cet utilisateur vous a déjà envoyé une demande');
    }

    await _api.sendFriendRequest(user.id);
    await loadAll();
  }

  Future<void> acceptRequest(String requestId) async {
    await _api.acceptFriendRequest(requestId);
    await loadAll();
  }

  Future<void> rejectRequest(String requestId) async {
    await _api.rejectFriendRequest(requestId);
    await loadAll();
  }

  Future<void> removeFriend(String friendId) async {
    await _api.removeFriend(friendId);
    await loadAll();
  }
}

final friendsProvider = NotifierProvider<FriendsNotifier, FriendsState>(
  FriendsNotifier.new,
);
