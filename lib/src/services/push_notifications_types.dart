enum PushPermission {
  granted,
  denied,
  prompt,
}

class PushSupport {
  const PushSupport({
    required this.isSupported,
    this.reason,
  });

  final bool isSupported;
  final String? reason;
}

abstract class PushNotificationsService {
  Future<PushSupport> checkSupport();
  Future<PushPermission> checkPermission();
  Future<bool> isSubscribed();
  Future<bool> enable();
  Future<void> disable();
}
