/**
 * /api/sync/rlp-state
 *
 * Smart bidirectional sync for rlp-state.json between local machine and server.
 *
 * GET  — Return the server's cached RLP state snapshot + lastSyncedAt
 * POST — Accept a local state snapshot, smart-merge with server cache, return merged result
 *
 * The server keeps its snapshot in-memory (resets on server restart).
 * For persistent server state, the merged result should also be written to
 * MISSION_CONTROL_DATA_DIR/rlp-state-cache.json on disk.
 */

import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { mergeRlpStates, RlpState } from '@/lib/rlp-state-sync'
import { join } from 'node:path'
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { logger } from '@/lib/logger'

// Resolve persistent cache path
function getCachePath(): string {
  const dataDir = process.env.MISSION_CONTROL_DATA_DIR || join(process.cwd(), '.data')
  mkdirSync(dataDir, { recursive: true })
  return join(dataDir, 'rlp-state-cache.json')
}

function readServerCache(): RlpState {
  try {
    const p = getCachePath()
    if (existsSync(p)) {
      const raw = readFileSync(p, 'utf-8')
      return JSON.parse(raw) as RlpState
    }
  } catch (err) {
    logger.warn({ err }, 'Failed to read RLP state server cache')
  }
  return {}
}

function writeServerCache(state: RlpState): void {
  try {
    const p = getCachePath()
    writeFileSync(p, JSON.stringify(state, null, 2), 'utf-8')
  } catch (err) {
    logger.warn({ err }, 'Failed to write RLP state server cache')
  }
}

/** Read rlp-state.json directly from the configured local path */
function readLocalRlpState(): { state: RlpState | null; path: string } {
  const rlpPath = process.env.RLP_STATE_PATH ||
    join(process.env.USERPROFILE || process.env.HOME || '', '.claude', 'workspace', 'rlp-state.json')
  try {
    if (existsSync(rlpPath)) {
      const raw = readFileSync(rlpPath, 'utf-8')
      return { state: JSON.parse(raw) as RlpState, path: rlpPath }
    }
  } catch (err) {
    logger.warn({ err, rlpPath }, 'Failed to read local RLP state file')
  }
  return { state: null, path: rlpPath }
}

/**
 * GET /api/sync/rlp-state
 * Returns the server's cached RLP state snapshot.
 */
export async function GET(request: NextRequest) {
  const auth = requireRole(request, 'viewer')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  const cache = readServerCache()
  return NextResponse.json({
    ok: true,
    state: cache,
    lastSyncedAt: cache.lastSyncedAt || null,
    todoCount: Array.isArray(cache.todos) ? cache.todos.length : 0,
  })
}

/**
 * POST /api/sync/rlp-state
 * Body: { state: RlpState }
 * Performs smart merge (newer wins, done never overwritten by pending).
 * Returns the merged state that should be written back to local.
 */
export async function POST(request: NextRequest) {
  const auth = requireRole(request, 'operator')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  let body: { state?: RlpState }
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const localState = body.state
  if (!localState || typeof localState !== 'object') {
    return NextResponse.json({ error: 'Missing state in request body' }, { status: 400 })
  }

  const serverCache = readServerCache()
  const { merged, changes } = mergeRlpStates(localState, serverCache)

  // Persist merged state as new server cache
  writeServerCache(merged)

  logger.info({ changes }, 'RLP state sync complete')

  return NextResponse.json({
    ok: true,
    merged,
    changes,
    lastSyncedAt: merged.lastSyncedAt,
    todoCount: Array.isArray(merged.todos) ? merged.todos.length : 0,
  })
}

/**
 * PATCH /api/sync/rlp-state
 * Server-initiated sync: reads local rlp-state.json from disk,
 * merges with server cache, writes merged result back to local file.
 * Used when the server has direct file access (self-hosted).
 */
export async function PATCH(request: NextRequest) {
  const auth = requireRole(request, 'operator')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  const { state: localState, path: rlpPath } = readLocalRlpState()
  if (!localState) {
    return NextResponse.json({
      ok: false,
      error: `Local RLP state file not found. Set RLP_STATE_PATH env or ensure file exists at ${rlpPath}`,
      path: rlpPath,
    }, { status: 404 })
  }

  const serverCache = readServerCache()
  const { merged, changes } = mergeRlpStates(localState, serverCache)

  // Write merged back to local file
  try {
    writeFileSync(rlpPath, JSON.stringify(merged, null, 2), 'utf-8')
  } catch (err) {
    logger.warn({ err, rlpPath }, 'Failed to write merged RLP state back to local file')
  }

  // Update server cache
  writeServerCache(merged)

  logger.info({ changes, rlpPath }, 'Server-side RLP state sync complete')

  return NextResponse.json({
    ok: true,
    merged,
    changes,
    lastSyncedAt: merged.lastSyncedAt,
    todoCount: Array.isArray(merged.todos) ? merged.todos.length : 0,
    path: rlpPath,
  })
}
