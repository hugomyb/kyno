#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build/web}"
SW_FILE="${BUILD_DIR}/flutter_service_worker.js"
MARKER="/* push-notifications */"

if [ ! -f "${SW_FILE}" ]; then
  echo "flutter_service_worker.js not found at ${SW_FILE}" >&2
  exit 1
fi

if grep -q "${MARKER}" "${SW_FILE}"; then
  exit 0
fi

cat <<'JS' >> "${SW_FILE}"

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

  const scopeUrl = self.registration && self.registration.scope ? self.registration.scope : '/';
  const iconUrl = new URL('icons/Icon-192.png', scopeUrl).toString();
  const title = data.title || 'Kyno';
  const payloadUrl = data.url || (data.data && data.data.url);
  const options = {
    body: data.body || '',
    tag: data.tag || 'kyno',
    icon: iconUrl,
    badge: iconUrl,
    data: Object.assign({
      url: payloadUrl || (scopeUrl + 'notifications'),
    }, data.data || {}),
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const scopeUrl = self.registration && self.registration.scope ? self.registration.scope : '/';
  const rawTarget = event.notification && event.notification.data && event.notification.data.url
    ? event.notification.data.url
    : (scopeUrl + 'notifications');
  const targetUrl = new URL(rawTarget, scopeUrl).toString();

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
JS
