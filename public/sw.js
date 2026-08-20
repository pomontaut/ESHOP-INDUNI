self.addEventListener('push', function(event) {
  let data = {};
  try { data = event.data ? event.data.json() : {}; } catch (e) {}
  const title = data.title || 'INDUNI E-Shop';
  event.waitUntil(self.registration.showNotification(title, {
    body: data.body || '',
    data: { url: data.url || '/catalogue.html' }
  }));
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || '/catalogue.html';
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(function(windowClients) {
      for (const client of windowClients) {
        if (client.url.includes('catalogue.html') && 'focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});
