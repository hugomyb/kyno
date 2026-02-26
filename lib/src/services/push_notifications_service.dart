import 'api_service.dart';
import 'push_notifications_types.dart';
import 'push_notifications_service_stub.dart'
    if (dart.library.html) 'push_notifications_service_web.dart';

PushNotificationsService createPushNotificationsService(ApiService api) {
  return createPushNotificationsServiceImpl(api);
}
