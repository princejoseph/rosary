// Minimal service worker — required for Chrome PWA install prompt.
// Caches audio and static assets on first visit; serves from cache when offline.

var CACHE = "japamala-v1";
var PRECACHE = ["/", "/manifest.json", "/icon-192.png", "/icon-512.png"];

self.addEventListener("install", function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(PRECACHE); })
  );
  self.skipWaiting();
});

self.addEventListener("activate", function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener("fetch", function (e) {
  // Cache-first for audio and icons; network-first for everything else.
  var url = e.request.url;
  if (url.includes("/audio/") || url.includes("/icon")) {
    e.respondWith(
      caches.match(e.request).then(function (cached) {
        return cached || fetch(e.request).then(function (resp) {
          return caches.open(CACHE).then(function (c) {
            c.put(e.request, resp.clone());
            return resp;
          });
        });
      })
    );
  } else {
    e.respondWith(
      fetch(e.request).catch(function () { return caches.match(e.request); })
    );
  }
});
