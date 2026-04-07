/**
 * RLP State Smart Sync
 *
 * Smart merge strategy for rlp-state.json between local machine and server.
 * Rules:
 *   - Prefer the item with the newer updatedAt / timestamp
 *   - Never overwrite a completed/done todo with an older pending version
 *   - Items only on one side are included as-is (additive merge)
 *   - "Garbage" = todos that are cancelled AND older than 7 days — excluded
 */

const DONE_STATUSES = new Set(['done', 'completed', 'cancelled'])
const STALE_GARBAGE_MS = 7 * 24 * 60 * 60 * 1000 // 7 days

export interface RlpTodo {
  id: number | string
  status: string
  title?: string
  updatedAt?: number
  createdAt?: number
  [key: string]: unknown
}

export interface RlpState {
  todos?: RlpTodo[]
  updatedAt?: number
  lastSyncedAt?: number
  [key: string]: unknown
}

/** Pick the timestamp of a todo (updatedAt preferred, then createdAt, then 0) */
function todoTimestamp(t: RlpTodo): number {
  return (t.updatedAt as number) || (t.createdAt as number) || 0
}

/** Return true if this todo is considered stale garbage */
function isGarbage(t: RlpTodo): boolean {
  if (t.status !== 'cancelled') return false
  const ts = todoTimestamp(t)
  if (!ts) return false
  return Date.now() - ts > STALE_GARBAGE_MS
}

/**
 * Smart merge two RLP state objects.
 * local = the state read from the local machine's rlp-state.json
 * server = the server's cached snapshot
 * Returns the merged state that should be written to both sides.
 */
export function mergeRlpStates(local: RlpState, server: RlpState): {
  merged: RlpState
  changes: { added: number; updated: number; skipped: number }
} {
  const localTodos: RlpTodo[] = Array.isArray(local.todos) ? local.todos : []
  const serverTodos: RlpTodo[] = Array.isArray(server.todos) ? server.todos : []

  const result = new Map<string | number, RlpTodo>()
  let added = 0
  let updated = 0
  let skipped = 0

  // Index server todos by id
  const serverMap = new Map<string | number, RlpTodo>()
  for (const t of serverTodos) {
    serverMap.set(t.id, t)
  }

  // Process local todos
  for (const local_t of localTodos) {
    if (isGarbage(local_t)) { skipped++; continue }
    const server_t = serverMap.get(local_t.id)
    if (!server_t) {
      result.set(local_t.id, local_t)
      added++
    } else {
      // Never overwrite a done/completed item with an older pending one
      const serverIsDone = DONE_STATUSES.has(server_t.status)
      const localIsDone = DONE_STATUSES.has(local_t.status)
      if (serverIsDone && !localIsDone) {
        // Server has it as done, local has it as pending -> keep server (done)
        result.set(server_t.id, server_t)
        skipped++
      } else {
        // Prefer newer timestamp
        const localTs = todoTimestamp(local_t)
        const serverTs = todoTimestamp(server_t)
        if (localTs >= serverTs) {
          result.set(local_t.id, local_t)
          if (localTs > serverTs) updated++
        } else {
          result.set(server_t.id, server_t)
          skipped++
        }
      }
    }
  }

  // Add server-only todos not in local (and not garbage)
  for (const server_t of serverTodos) {
    if (result.has(server_t.id)) continue
    if (isGarbage(server_t)) { skipped++; continue }
    result.set(server_t.id, server_t)
    added++
  }

  // Preserve original ordering by id if possible, else sort by id numerically
  const mergedTodos = Array.from(result.values()).sort((a, b) => {
    const an = Number(a.id) || 0
    const bn = Number(b.id) || 0
    return an - bn
  })

  // Merge top-level metadata: prefer local for non-todo fields, update timestamps
  const merged: RlpState = {
    ...server,
    ...local,
    todos: mergedTodos,
    lastSyncedAt: Date.now(),
  }

  return { merged, changes: { added, updated, skipped } }
}
