/*
 * Service worker: makes the app installable and playable offline once it has
 * been opened. Network first (so a running dev server always wins), falling
 * back to the cached copy when the device is offline.
 */
const CACHE = 'guitar-sim-v2';
const SHELL = [
  './', 'index.html', 'styles.css', 'manifest.webmanifest',
  'src/main.js', 'src/state.js',
  'src/theory/notes.js', 'src/theory/tunings.js', 'src/theory/fretboard.js', 'src/theory/scales.js', 'src/theory/chords.js', 'src/theory/chord-voicings.js',
  'src/audio/engine.js', 'src/audio/string-processor.js', 'src/audio/effects.js', 'src/audio/presets.js',
  'src/ui/guitar-canvas.js', 'src/ui/interaction.js', 'src/ui/knob.js', 'src/ui/controls.js', 'src/ui/learning-panel.js', 'src/ui/qr.js',
  'icons/icon-192.png', 'icons/apple-touch-icon.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  // Live answers from the dev server (/__lan.json) are never cached.
  if (request.method !== 'GET' || url.origin !== self.location.origin || url.pathname.includes('/__')) return;
  event.respondWith(
    fetch(request).then((response) => {
      if (response && response.ok) {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(request, copy)).catch(() => {});
      }
      return response;
    }).catch(() => caches.match(request, { ignoreSearch: true }).then((hit) => hit || caches.match('index.html'))),
  );
});
