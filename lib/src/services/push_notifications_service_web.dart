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
  Future<PushDiagnostics?> buildDiagnostics() async {
    final notificationsSupported = html.Notification.supported;
    final serviceWorkerSupported = html.window.navigator.serviceWorker != null;
    final displayModeStandalone = html.window.matchMedia('(display-mode: standalone)').matches;
    final isSecureContext = html.window.isSecureContext ?? false;
    final hasServiceWorkerController =
        html.window.navigator.serviceWorker?.controller != null;
    final userAgent = html.window.navigator.userAgent;
    bool serviceWorkerReady = false;
    bool pushManagerSupported = false;
    bool hasRegistration = false;
    String registrationScope = '';
    String registrationScriptUrl = '';
    String registrationState = '';
    String registrationSource = 'none';
    String? serviceWorkerError;

    if (serviceWorkerSupported) {
      try {
        final registration = await _getRegistration();
        serviceWorkerReady = registration != null;
        pushManagerSupported = registration?.pushManager != null;
        if (registration != null) {
          hasRegistration = true;
          registrationScope = registration.scope ?? '';
          registrationScriptUrl = registration.active?.scriptUrl ?? '';
          registrationState = registration.active?.state ?? '';
          registrationSource = 'ready/getRegistration';
        }
      } catch (e) {
        serviceWorkerError = e.toString();
      }
    }

    return PushDiagnostics(
      notificationsSupported: notificationsSupported,
      serviceWorkerSupported: serviceWorkerSupported,
      serviceWorkerReady: serviceWorkerReady,
      pushManagerSupported: pushManagerSupported,
      displayModeStandalone: displayModeStandalone,
      hasServiceWorkerController: hasServiceWorkerController,
      isSecureContext: isSecureContext,
      userAgent: userAgent,
      hasRegistration: hasRegistration,
      registrationScope: registrationScope,
      registrationScriptUrl: registrationScriptUrl,
      registrationState: registrationState,
      currentUrl: html.window.location.href,
      baseUrl: html.document.baseUri ?? '',
      registrationSource: registrationSource,
      serviceWorkerError: serviceWorkerError,
    );
  }

  @override
  Future<bool> forceRegisterServiceWorker() async {
    final swContainer = html.window.navigator.serviceWorker;
    if (swContainer == null) {
      return false;
    }
    try {
      final base = html.document.baseUri ?? '/';
      final swUrl = Uri.parse(base).resolve('flutter_service_worker.js').toString();
      final scope = Uri.parse(base).path.endsWith('/') ? Uri.parse(base).path : '${Uri.parse(base).path}/';
      final registration = await swContainer.register(swUrl, {
        'scope': scope,
        'updateViaCache': 'none',
      });
      await registration.update();
      final ready = await _getRegistration();
      return ready != null;
    } catch (e) {
      throw Exception('SW register failed: $e');
    }
  }

  Future<html.ServiceWorkerRegistration?> _getRegistration() async {
    final swContainer = html.window.navigator.serviceWorker;
    if (swContainer == null) {
      return null;
    }
    try {
      final current = html.window.location.href.split('#').first;
      final direct = await swContainer.getRegistration(current).timeout(
            const Duration(seconds: 2),
          );
      return direct;
    } catch (_) {
      // Ignore and fallback to ready.
    }
    try {
      final ready = swContainer.ready;
      return await ready.timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
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
