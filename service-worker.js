const CACHE_NAME = "semeia-cache-v2";
const ASSETS = [
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// index.html (and any Supabase call) always goes to the network first,
// so updates show up immediately. Only static assets fall back to cache
// when there's no connection.
self.addEventListener("fetch", (event) => {
  const url = event.request.url;
  const isHTML = event.request.mode === "navigate" || url.endsWith(".html") || url.endsWith("/");

  if (url.includes("supabase.co") || url.includes("supabase.in")) {
    return; // let Supabase requests hit the network directly
  }

  if (isHTML) {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
