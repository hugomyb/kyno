import 'api_service.dart';
import 'push_notifications_types.dart';

PushNotificationsService createPushNotificationsServiceImpl(ApiService api) {
  return _PushNotificationsServiceStub();
}

class _PushNotificationsServiceStub implements PushNotificationsService {
  @override
  Future<PushSupport> checkSupport() async {
    return const PushSupport(isSupported: false, reason: 'Non pris en charge');
  }

  @override
  Future<PushDiagnostics?> buildDiagnostics() async {
    return null;
  }

  @override
  Future<PushPermission> checkPermission() async {
    return PushPermission.denied;
  }

  @override
  Future<bool> isSubscribed() async {
    return false;
  }

  @override
  Future<bool> enable() async {
    return false;
  }

  @override
  Future<void> disable() async {}
}
