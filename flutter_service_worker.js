'use strict';

self.addEventListener('install', () => {
  self.skipWaiting();
});


/* push-notifications */
self.addEventListener('push', function (event) {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: 'Kyno', body: event.data.text() };
    }
  }

  const scopeUrl = self.registration && self.registration.scope ? self.registration.scope : self.location.origin + '/';
  const iconUrl = new URL('icons/Icon-192.png', scopeUrl).toString();
  const title = data.title || 'Kyno';
  const payloadUrl = data.url || (data.data && data.data.url);
  const options = {
    body: data.body || '',
    tag: data.tag || 'kyno',
    icon: iconUrl,
    badge: iconUrl,
    data: Object.assign({
      url: payloadUrl || '#/notifications',
    }, data.data || {}),
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const scopeUrl = self.registration && self.registration.scope ? self.registration.scope : self.location.origin + '/';
  const rawTarget = event.notification && event.notification.data && event.notification.data.url
    ? event.notification.data.url
    : (scopeUrl + '#/notifications');
  let targetUrl;
  try {
    const scopeBase = new URL(scopeUrl, self.location.href);
    const candidate = new URL(rawTarget, scopeBase);
    targetUrl = candidate.origin === scopeBase.origin
      ? candidate.toString()
      : new URL('#/notifications', scopeBase).toString();
  } catch (e) {
    targetUrl = new URL('#/notifications', self.location.href).toString();
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (const client of clientList) {
        if ('navigate' in client) {
          client.navigate(targetUrl);
        }
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});
