const C='m4-hub-v2';const A=['./','./index.html','./manifest.json','./icon-192.png','./icon-512.png','./app-icon.png','./hero-photo.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(C).then(x=>x.addAll(A)));self.skipWaiting()});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{if(e.request.method!=='GET')return;const u=new URL(e.request.url);if(u.hostname.includes('supabase.co')||u.hostname.includes('jsdelivr.net')){e.respondWith(fetch(e.request));return}e.respondWith(fetch(e.request).then(r=>{let q=r.clone();caches.open(C).then(x=>x.put(e.request,q));return r}).catch(()=>caches.match(e.request).then(r=>r||caches.match('./index.html'))))});
self.addEventListener("push", event => {
  let data = {};

  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = {
      title: "M4 Hub",
      body: event.data ? event.data.text() : "You have a new family update."
    };
  }

  const title = data.title || "M4 Hub";
  const options = {
    body: data.body || "You have a new family update.",
    icon: "./icon-192.png",
    badge: "./icon-192.png",
    data: {
      url: data.url || "./"
    }
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

self.addEventListener("notificationclick", event => {
  event.notification.close();

  const url = event.notification.data?.url || "./";

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true })
      .then(windowClients => {
        for (const client of windowClients) {
          if ("focus" in client) {
            client.navigate(url);
            return client.focus();
          }
        }

        if (clients.openWindow) {
          return clients.openWindow(url);
        }
      })
  );
});
