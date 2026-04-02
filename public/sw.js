/**
 * Mission Control Service Worker
 * Provides offline caching, background sync for offline saves, and PWA support.
 */

const CACHE_NAME = 'mission-control-v1';
const OFFLINE_QUEUE_KEY = 'mc-offline-queue';

// App shell pages to pre-cache
const PRECACHE_URLS = [
  '/',
  '/manifest.json',
  '/icon.png',
  '/apple-icon.png',
];

// ---------------------------------------------------------------------------
// Install: pre-cache app shell
// ---------------------------------------------------------------------------
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

// ---------------------------------------------------------------------------
// Activate: clean up old caches
// ---------------------------------------------------------------------------
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((k) => k !== CACHE_NAME)
          .map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// ---------------------------------------------------------------------------
// Fetch: network-first for API/navigation, cache-first for static assets
// ---------------------------------------------------------------------------
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle same-origin requests
  if (url.origin !== self.location.origin) return;

  // API requests: network-first, queue mutations when offline
  if (url.pathname.startsWith('/api/')) {
    if (request.method !== 'GET') {
      event.respondWith(handleMutationOffline(request));
      return;
    }
    event.respondWith(
      fetch(request)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then((c) => c.put(request, clone));
          return res;
        })
        .catch(() => caches.match(request).then((r) => r || new Response('{"error":"offline"}', { headers: { 'Content-Type': 'application/json' } })))
    );
    return;
  }

  // Navigation requests: network-first with offline fallback to cached root
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then((c) => c.put(request, clone));
          return res;
        })
        .catch(() => caches.match('/') || caches.match(request))
    );
    return;
  }

  // Static assets (_next/static, images): cache-first
  if (
    url.pathname.startsWith('/_next/static/') ||
    url.pathname.startsWith('/brand/') ||
    url.pathname.match(/\.(png|jpg|jpeg|svg|ico|woff2?|css|js)$/)
  ) {
    event.respondWith(
      caches.match(request).then(
        (cached) =>
          cached ||
          fetch(request).then((res) => {
            caches.open(CACHE_NAME).then((c) => c.put(request, res.clone()));
            return res;
          })
      )
    );
    return;
  }
});

// ---------------------------------------------------------------------------
// Offline mutation queuing: store failed mutating requests in IndexedDB
// ---------------------------------------------------------------------------
async function handleMutationOffline(request) {
  try {
    const res = await fetch(request.clone());
    return res;
  } catch (_err) {
    // Offline: queue the request payload in IndexedDB
    await queueOfflineRequest(request);
    return new Response(
      JSON.stringify({ queued: true, message: 'Saved offline; will sync when reconnected.' }),
      { status: 202, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

async function queueOfflineRequest(request) {
  try {
    const body = await request.text();
    const entry = {
      id: Date.now() + Math.random(),
      url: request.url,
      method: request.method,
      headers: Object.fromEntries(request.headers.entries()),
      body,
      timestamp: new Date().toISOString(),
    };
    const db = await openOfflineDB();
    await dbPut(db, entry);
  } catch (e) {
    console.warn('[SW] Failed to queue offline request', e);
  }
}

// ---------------------------------------------------------------------------
// Background Sync: replay queued requests when back online
// ---------------------------------------------------------------------------
self.addEventListener('sync', (event) => {
  if (event.tag === 'mc-offline-sync') {
    event.waitUntil(replayOfflineQueue());
  }
});

// Also attempt replay when online event fires (for browsers without BackgroundSync)
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'ONLINE_SYNC') {
    replayOfflineQueue();
  }
});

async function replayOfflineQueue() {
  const db = await openOfflineDB();
  const entries = await dbGetAll(db);
  if (entries.length === 0) return;

  const replayed = [];
  for (const entry of entries) {
    try {
      await fetch(entry.url, {
        method: entry.method,
        headers: entry.headers,
        body: entry.body || undefined,
      });
      replayed.push(entry.id);
    } catch (_e) {
      // Still offline; leave in queue
      break;
    }
  }

  for (const id of replayed) {
    await dbDelete(db, id);
  }

  if (replayed.length > 0) {
    // Notify all open windows that sync completed
    const clients = await self.clients.matchAll({ includeUncontrolled: true });
    clients.forEach((client) =>
      client.postMessage({ type: 'SYNC_COMPLETE', count: replayed.length })
    );
  }
}

// ---------------------------------------------------------------------------
// IndexedDB helpers (no dependencies)
// ---------------------------------------------------------------------------
function openOfflineDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open('mc-offline', 1);
    req.onupgradeneeded = (e) => {
      const db = e.target.result;
      if (!db.objectStoreNames.contains('queue')) {
        db.createObjectStore('queue', { keyPath: 'id' });
      }
    };
    req.onsuccess = (e) => resolve(e.target.result);
    req.onerror = (e) => reject(e.target.error);
  });
}

function dbPut(db, entry) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('queue', 'readwrite');
    const req = tx.objectStore('queue').put(entry);
    req.onsuccess = () => resolve();
    req.onerror = (e) => reject(e.target.error);
  });
}

function dbGetAll(db) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('queue', 'readonly');
    const req = tx.objectStore('queue').getAll();
    req.onsuccess = (e) => resolve(e.target.result);
    req.onerror = (e) => reject(e.target.error);
  });
}

function dbDelete(db, id) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('queue', 'readwrite');
    const req = tx.objectStore('queue').delete(id);
    req.onsuccess = () => resolve();
    req.onerror = (e) => reject(e.target.error);
  });
}
