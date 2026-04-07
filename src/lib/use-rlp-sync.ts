'use client'

/**
 * useRlpSync — auto-syncs rlp-state.json on SSE/connection restore.
 *
 * Strategy:
 *   1. On mount and on reconnect, POST local rlp-state to /api/sync/rlp-state
 *   2. Server returns smart-merged state (newer wins, done never overwritten)
 *   3. UI shows "Last synced" timestamp and a brief toast on completion
 *
 * The hook reads the local RLP state file via /api/memory (file browser)
 * or directly from a known path exposed via a dedicated endpoint.
 * It stores last-synced metadata in localStorage for persistence.
 */

import { useEffect, useRef, useCallback, useState } from 'react'
import { useMissionControl } from '@/store'

const LS_KEY = 'mc:rlp-last-synced'
const RLP_STATE_ENDPOINT = '/api/sync/rlp-state'

export interface RlpSyncStatus {
  lastSyncedAt: number | null
  syncing: boolean
  lastError: string | null
  lastChanges: { added: number; updated: number; skipped: number } | null
  toastMessage: string | null
  dismissToast: () => void
  triggerSync: () => void
}

function loadLastSynced(): number | null {
  try {
    const v = localStorage.getItem(LS_KEY)
    return v ? Number(v) : null
  } catch {
    return null
  }
}

function saveLastSynced(ts: number): void {
  try {
    localStorage.setItem(LS_KEY, String(ts))
  } catch { /* ignore */ }
}

/** Try server-side PATCH first (direct file access), fall back to GET-only */
async function doServerSync(): Promise<{
  merged?: object
  changes?: { added: number; updated: number; skipped: number }
  lastSyncedAt?: number
  todoCount?: number
  ok: boolean
  fallback?: boolean
}> {
  // Prefer PATCH: server reads+merges+writes the local file itself
  try {
    const res = await fetch(RLP_STATE_ENDPOINT, { method: 'PATCH' })
    if (res.ok) {
      const data = await res.json()
      if (data.ok) return data
    }
  } catch { /* fall through */ }

  // Fallback: GET the server cache snapshot only
  try {
    const res = await fetch(RLP_STATE_ENDPOINT)
    if (res.ok) {
      const data = await res.json()
      return { ok: true, lastSyncedAt: data.lastSyncedAt, todoCount: data.todoCount, fallback: true }
    }
  } catch { /* ignore */ }

  return { ok: false }
}

export function useRlpSync(): RlpSyncStatus {
  const { connection } = useMissionControl()
  const [lastSyncedAt, setLastSyncedAt] = useState<number | null>(loadLastSynced)
  const [syncing, setSyncing] = useState(false)
  const [lastError, setLastError] = useState<string | null>(null)
  const [lastChanges, setLastChanges] = useState<{ added: number; updated: number; skipped: number } | null>(null)
  const [toastMessage, setToastMessage] = useState<string | null>(null)
  const toastTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)
  const prevConnectedRef = useRef<boolean>(false)
  const syncInFlightRef = useRef(false)

  const dismissToast = useCallback(() => {
    if (toastTimerRef.current) clearTimeout(toastTimerRef.current)
    setToastMessage(null)
  }, [])

  const showToast = useCallback((msg: string, durationMs = 5000) => {
    setToastMessage(msg)
    if (toastTimerRef.current) clearTimeout(toastTimerRef.current)
    toastTimerRef.current = setTimeout(() => setToastMessage(null), durationMs)
  }, [])

  const triggerSync = useCallback(async () => {
    if (syncInFlightRef.current) return
    syncInFlightRef.current = true
    setSyncing(true)
    setLastError(null)

    try {
      const result = await doServerSync()
      if (!result.ok) {
        setLastError('Sync failed — server unreachable')
        showToast('Sync failed', 4000)
        return
      }

      const ts = result.lastSyncedAt || Date.now()
      setLastSyncedAt(ts)
      saveLastSynced(ts)

      if (result.changes) {
        setLastChanges(result.changes)
        const { added, updated } = result.changes
        if (added > 0 || updated > 0) {
          showToast(`Synced: +${added} new, ${updated} updated`)
        } else {
          showToast('Already up to date')
        }
      } else if (result.fallback) {
        showToast('Sync complete (read-only)')
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Unknown error'
      setLastError(msg)
      showToast('Sync error', 4000)
    } finally {
      setSyncing(false)
      syncInFlightRef.current = false
    }
  }, [showToast])

  // Auto-sync on connection restore (SSE reconnect)
  useEffect(() => {
    const isNowConnected = !!(connection.sseConnected)
    const wasConnected = prevConnectedRef.current

    if (isNowConnected && !wasConnected) {
      // Connection just restored — trigger sync
      triggerSync()
    }
    prevConnectedRef.current = isNowConnected
  }, [connection.sseConnected, triggerSync])

  // Initial sync on mount
  useEffect(() => {
    triggerSync()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return { lastSyncedAt, syncing, lastError, lastChanges, toastMessage, dismissToast, triggerSync }
}
