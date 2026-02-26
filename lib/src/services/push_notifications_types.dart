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

class PushDiagnostics {
  const PushDiagnostics({
    required this.notificationsSupported,
    required this.serviceWorkerSupported,
    required this.serviceWorkerReady,
    required this.pushManagerSupported,
    this.serviceWorkerError,
  });

  final bool notificationsSupported;
  final bool serviceWorkerSupported;
  final bool serviceWorkerReady;
  final bool pushManagerSupported;
  final String? serviceWorkerError;
}

abstract class PushNotificationsService {
  Future<PushSupport> checkSupport();
  Future<PushDiagnostics?> buildDiagnostics();
  Future<PushPermission> checkPermission();
  Future<bool> isSubscribed();
  Future<bool> enable();
  Future<void> disable();
}
