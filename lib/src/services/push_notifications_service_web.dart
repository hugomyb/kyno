import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'api_service.dart';
import 'push_notifications_types.dart';

PushNotificationsService createPushNotificationsServiceImpl(ApiService api) {
  return _PushNotificationsServiceWeb(api);
}

class _PushNotificationsServiceWeb implements PushNotificationsService {
  _PushNotificationsServiceWeb(this._api);

  final ApiService _api;

  @override
  Future<PushSupport> checkSupport() async {
    if (!html.Notification.supported) {
      return const PushSupport(isSupported: false, reason: 'Notifications non prises en charge');
    }

    if (html.window.navigator.serviceWorker == null) {
      return const PushSupport(isSupported: false, reason: 'Service worker indisponible');
    }

    final registration = await _getRegistration();
    if (registration == null) {
      return const PushSupport(isSupported: false, reason: 'Service worker non actif');
    }

    final pushManager = registration.pushManager;
    if (pushManager == null) {
      return const PushSupport(isSupported: false, reason: 'Push indisponible');
    }

    return const PushSupport(isSupported: true);
  }

  @override
  Future<PushPermission> checkPermission() async {
    switch (html.Notification.permission) {
      case 'granted':
        return PushPermission.granted;
      case 'denied':
        return PushPermission.denied;
      default:
        return PushPermission.prompt;
    }
  }

  @override
  Future<bool> isSubscribed() async {
    final registration = await _getRegistration();
    if (registration == null) {
      return false;
    }

    final pushManager = registration.pushManager;
    if (pushManager == null) {
      return false;
    }

    final subscription = await _getSubscription(pushManager);
    return subscription != null;
  }

  @override
  Future<bool> enable() async {
    final support = await checkSupport();
    if (!support.isSupported) {
      return false;
    }

    final permission = await _requestPermission();
    if (permission != PushPermission.granted) {
      return false;
    }

    final registration = await _getRegistration();
    if (registration == null) {
      return false;
    }

    final pushManager = registration.pushManager;
    if (pushManager == null) {
      return false;
    }

    var subscription = await _getSubscription(pushManager);
    if (subscription == null) {
      final publicKey = await _api.fetchVapidPublicKey();
      if (publicKey.trim().isEmpty) {
        return false;
      }

      final options = {
        'userVisibleOnly': true,
        'applicationServerKey': _decodeVapidKey(publicKey),
      };

      subscription = await _subscribe(pushManager, options);
      if (subscription == null) {
        return false;
      }
    }

    final data = _extractSubscription(subscription);
    if (data.endpoint.isEmpty || data.p256dhKey.isEmpty || data.authKey.isEmpty) {
      return false;
    }

    await _api.registerPushSubscription(
      endpoint: data.endpoint,
      p256dhKey: data.p256dhKey,
      authKey: data.authKey,
      contentEncoding: _contentEncoding(),
      userAgent: html.window.navigator.userAgent,
    );

    return true;
  }

  @override
  Future<void> disable() async {
    final registration = await _getRegistration();
    if (registration == null) {
      return;
    }

    final pushManager = registration.pushManager;
    if (pushManager == null) {
      return;
    }

    final subscription = await _getSubscription(pushManager);
    if (subscription == null) {
      return;
    }

    final endpoint = subscription.endpoint;
    await subscription.unsubscribe();

    if (endpoint != null && endpoint.isNotEmpty) {
      await _api.unregisterPushSubscription(endpoint: endpoint);
    }
  }

  Future<html.ServiceWorkerRegistration?> _getRegistration() async {
    try {
      final reg = await html.window.navigator.serviceWorker?.ready;
      return reg;
    } catch (_) {
      return null;
    }
  }

  Future<html.PushSubscription?> _getSubscription(html.PushManager pushManager) async {
    try {
      return await pushManager.getSubscription();
    } catch (_) {
      return null;
    }
  }

  Future<html.PushSubscription?> _subscribe(
    html.PushManager pushManager,
    Map<String, dynamic> options,
  ) async {
    try {
      return await pushManager.subscribe(options);
    } catch (_) {
      return null;
    }
  }

  Future<PushPermission> _requestPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      switch (permission) {
        case 'granted':
          return PushPermission.granted;
        case 'denied':
          return PushPermission.denied;
        default:
          return PushPermission.prompt;
      }
    } catch (_) {
      return PushPermission.denied;
    }
  }

  Uint8List _decodeVapidKey(String key) {
    var normalized = key.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return Uint8List.fromList(base64Decode(normalized));
  }

  _SubscriptionData _extractSubscription(html.PushSubscription subscription) {
    final endpoint = subscription.endpoint ?? '';
    final p256dh = _encodeKey(subscription.getKey('p256dh'));
    final auth = _encodeKey(subscription.getKey('auth'));
    return _SubscriptionData(
      endpoint: endpoint,
      p256dhKey: p256dh,
      authKey: auth,
    );
  }

  String _encodeKey(ByteBuffer? buffer) {
    if (buffer == null) {
      return '';
    }
    final bytes = Uint8List.view(buffer);
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _contentEncoding() {
    final encodings = html.PushManager.supportedContentEncodings;
    if (encodings == null || encodings.isEmpty) {
      return 'aes128gcm';
    }
    if (encodings.contains('aes128gcm')) {
      return 'aes128gcm';
    }
    return encodings.first;
  }
}

class _SubscriptionData {
  const _SubscriptionData({
    this.endpoint = '',
    this.p256dhKey = '',
    this.authKey = '',
  });

  final String endpoint;
  final String p256dhKey;
  final String authKey;
}
