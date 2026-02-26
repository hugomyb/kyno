import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/push_notifications_service.dart';
import '../services/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageProvider);
  return ApiClient(storage);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthService(client);
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiService(client);
});

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return createPushNotificationsService(api);
});
