'use client'

import { useEffect, useState } from 'react'

/**
 * PWAInit: registers the service worker and displays an offline banner.
 * Handles background-sync trigger when the browser comes back online.
 */
export function PWAInit() {
  const [isOffline, setIsOffline] = useState(false)
  const [syncNotice, setSyncNotice] = useState<string | null>(null)

  useEffect(() => {
    // Register service worker
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker
        .register('/sw.js', { scope: '/' })
        .then((reg) => {
          // Listen for sync-complete messages from SW
          navigator.serviceWorker.addEventListener('message', (event) => {
            if (event.data?.type === 'SYNC_COMPLETE') {
              const count = event.data.count as number
              setSyncNotice(`Synced ${count} offline change${count === 1 ? '' : 's'} to server.`)
              setTimeout(() => setSyncNotice(null), 5000)
            }
          })
          return reg
        })
        .catch((err) => console.warn('[PWA] SW registration failed:', err))
    }

    // Track online/offline state
    const handleOffline = () => setIsOffline(true)
    const handleOnline = () => {
      setIsOffline(false)
      // Trigger background sync replay via message to SW
      if (navigator.serviceWorker.controller) {
        navigator.serviceWorker.controller.postMessage({ type: 'ONLINE_SYNC' })
      }
      // Also use BackgroundSync API if supported
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.ready.then((reg) => {
          if ('sync' in reg) {
            ;(reg as any).sync.register('mc-offline-sync').catch(() => {})
          }
        })
      }
    }

    setIsOffline(!navigator.onLine)
    window.addEventListener('offline', handleOffline)
    window.addEventListener('online', handleOnline)

    return () => {
      window.removeEventListener('offline', handleOffline)
      window.removeEventListener('online', handleOnline)
    }
  }, [])

  return (
    <>
      {isOffline && (
        <div
          role="status"
          aria-live="polite"
          className="fixed top-0 left-0 right-0 z-[9999] flex items-center justify-center gap-2 bg-yellow-500 px-4 py-2 text-sm font-medium text-black shadow-lg"
        >
          <span>Offline Mode</span>
          <span className="text-xs opacity-80">
            — Changes are saved locally and will sync when you reconnect.
          </span>
        </div>
      )}
      {syncNotice && !isOffline && (
        <div
          role="status"
          aria-live="polite"
          className="fixed top-0 left-0 right-0 z-[9999] flex items-center justify-center gap-2 bg-green-600 px-4 py-2 text-sm font-medium text-white shadow-lg"
        >
          {syncNotice}
        </div>
      )}
    </>
  )
}
