const CACHE_NAME = 'mzugoss-library-shell-v3';
const APP_SHELL = ['./', './index.html', './manifest.webmanifest', './icons/icon-192.png', './icons/icon-512.png'];
self.addEventListener('install', event => { event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(APP_SHELL)).then(() => self.skipWaiting())); });
self.addEventListener('activate', event => { event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', event => {
  const req = event.request; const url = new URL(req.url);
  // Keep database/auth requests online; never serve stale Supabase data from the shell cache.
  if (url.origin !== self.location.origin || req.method !== 'GET') return;
  event.respondWith(fetch(req).then(response => { if (response && response.ok) { const copy = response.clone(); caches.open(CACHE_NAME).then(cache => cache.put(req, copy)); } return response; }).catch(() => caches.match(req).then(cached => cached || caches.match('./index.html'))));
});
