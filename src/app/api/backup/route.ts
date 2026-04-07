import { NextRequest, NextResponse } from 'next/server'
import { requireRole } from '@/lib/auth'
import { getDatabase, logAuditEvent } from '@/lib/db'
import { config, ensureDirExists } from '@/lib/config'
import { join, dirname } from 'path'
import { readdirSync, statSync, unlinkSync, copyFileSync, readFileSync, existsSync } from 'fs'
import { heavyLimiter } from '@/lib/rate-limit'
import { logger } from '@/lib/logger'
import { runOpenClaw } from '@/lib/command'

// Path to RLP state file (Windows path resolved at runtime)
const RLP_STATE_PATH = 'C:\\Users\\micha\\.claude\\workspace\\rlp-state.json'
const RLP_BACKUP_DIR = 'C:\\Users\\micha\\.claude\\workspace\\backups'

const BACKUP_DIR = join(dirname(config.dbPath), 'backups')
const MAX_BACKUPS = 50

/**
 * GET /api/backup - List existing backups (admin only)
 */
export async function GET(request: NextRequest) {
  const auth = requireRole(request, 'admin')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  ensureDirExists(BACKUP_DIR)

  try {
    const files = readdirSync(BACKUP_DIR)
      .filter(f => f.endsWith('.db'))
      .map(f => {
        const stat = statSync(join(BACKUP_DIR, f))
        return {
          name: f,
          type: 'db',
          size: stat.size,
          created_at: Math.floor(stat.mtimeMs / 1000),
        }
      })
      .sort((a, b) => b.created_at - a.created_at)

    // Also list RLP JSON backups
    let rlpBackups: Array<{ name: string; type: string; size: number; created_at: number }> = []
    try {
      ensureDirExists(RLP_BACKUP_DIR)
      rlpBackups = readdirSync(RLP_BACKUP_DIR)
        .filter(f => f.startsWith('rlp-state-') && f.endsWith('.json'))
        .map(f => {
          const stat = statSync(join(RLP_BACKUP_DIR, f))
          return { name: f, type: 'rlp', size: stat.size, created_at: Math.floor(stat.mtimeMs / 1000) }
        })
        .sort((a, b) => b.created_at - a.created_at)
    } catch { /* best-effort */ }

    // Last saved timestamp from RLP state file
    let lastSaved: number | null = null
    try {
      if (existsSync(RLP_STATE_PATH)) {
        const stat = statSync(RLP_STATE_PATH)
        lastSaved = Math.floor(stat.mtimeMs / 1000)
      }
    } catch { /* best-effort */ }

    return NextResponse.json({ backups: files, rlpBackups, lastSaved, dir: BACKUP_DIR })
  } catch {
    return NextResponse.json({ backups: [], rlpBackups: [], lastSaved: null, dir: BACKUP_DIR })
  }
}

/**
 * POST /api/backup - Create a new backup (admin only)
 */
export async function POST(request: NextRequest) {
  const auth = requireRole(request, 'admin')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  const rateCheck = heavyLimiter(request)
  if (rateCheck) return rateCheck

  const target = request.nextUrl.searchParams.get('target')

  // Gateway state backup via `openclaw backup create`
  if (target === 'gateway') {
    ensureDirExists(BACKUP_DIR)
    const ipAddress = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
    try {
      let stdout: string
      let stderr: string
      try {
        const result = await runOpenClaw(['backup', 'create', '--output', BACKUP_DIR], { timeoutMs: 60000 })
        stdout = result.stdout
        stderr = result.stderr
      } catch (error: any) {
        // openclaw backup may exit non-zero despite success — check output
        stdout = error.stdout || ''
        stderr = error.stderr || ''
        const combined = `${stdout}\n${stderr}`
        if (!combined.includes('Created')) {
          const message = stderr || error.message || 'Unknown error'
          logger.error({ err: error }, 'Gateway backup failed')
          return NextResponse.json({ error: `Gateway backup failed: ${message}` }, { status: 500 })
        }
      }

      const output = (stdout || stderr).trim()

      logAuditEvent({
        action: 'openclaw.backup',
        actor: auth.user.username,
        actor_id: auth.user.id,
        detail: { output },
        ip_address: ipAddress,
      })

      return NextResponse.json({ success: true, output })
    } catch (error: any) {
      logger.error({ err: error }, 'Gateway backup failed')
      return NextResponse.json({ error: `Gateway backup failed: ${error.message}` }, { status: 500 })
    }
  }

  // Default: MC SQLite backup
  ensureDirExists(BACKUP_DIR)

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').slice(0, 19)
  const backupPath = join(BACKUP_DIR, `mc-backup-${timestamp}.db`)

  try {
    const db = getDatabase()
    await db.backup(backupPath)

    const stat = statSync(backupPath)

    const ipAddress = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
    logAuditEvent({
      action: 'backup_create',
      actor: auth.user.username,
      actor_id: auth.user.id,
      detail: { path: backupPath, size: stat.size },
      ip_address: ipAddress,
    })

    // Prune old backups beyond MAX_BACKUPS
    pruneOldBackups()

    // Also backup RLP state JSON if it exists
    let rlpBackup: { name: string; size: number; created_at: number } | null = null
    try {
      if (existsSync(RLP_STATE_PATH)) {
        ensureDirExists(RLP_BACKUP_DIR)
        const rlpBackupName = `rlp-state-${timestamp}.json`
        const rlpBackupPath = join(RLP_BACKUP_DIR, rlpBackupName)
        copyFileSync(RLP_STATE_PATH, rlpBackupPath)
        const rlpStat = statSync(rlpBackupPath)
        rlpBackup = { name: rlpBackupName, size: rlpStat.size, created_at: Math.floor(rlpStat.mtimeMs / 1000) }
        pruneOldRlpBackups()
      }
    } catch (rlpErr: any) {
      logger.warn({ err: rlpErr }, 'RLP state backup skipped (non-fatal)')
    }

    return NextResponse.json({
      success: true,
      backup: {
        name: `mc-backup-${timestamp}.db`,
        size: stat.size,
        created_at: Math.floor(stat.mtimeMs / 1000),
      },
      rlpBackup,
      lastSaved: Math.floor(Date.now() / 1000),
    })
  } catch (error: any) {
    logger.error({ err: error }, 'Backup failed')
    return NextResponse.json({ error: `Backup failed: ${error.message}` }, { status: 500 })
  }
}

/**
 * DELETE /api/backup?name=<filename> - Delete a specific backup (admin only)
 */
export async function DELETE(request: NextRequest) {
  const auth = requireRole(request, 'admin')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  let body: any
  try { body = await request.json() } catch { return NextResponse.json({ error: 'Request body required' }, { status: 400 }) }
  const name = body.name

  if (!name || !name.endsWith('.db') || name.includes('/') || name.includes('..')) {
    return NextResponse.json({ error: 'Invalid backup name' }, { status: 400 })
  }

  try {
    const fullPath = join(BACKUP_DIR, name)
    unlinkSync(fullPath)

    const ipAddress = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
    logAuditEvent({
      action: 'backup_delete',
      actor: auth.user.username,
      actor_id: auth.user.id,
      detail: { name },
      ip_address: ipAddress,
    })

    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: 'Backup not found' }, { status: 404 })
  }
}

/**
 * PATCH /api/backup - Restore an RLP state backup (admin only)
 * Body: { name: string } — filename from rlpBackups list
 */
export async function PATCH(request: NextRequest) {
  const auth = requireRole(request, 'admin')
  if ('error' in auth) return NextResponse.json({ error: auth.error }, { status: auth.status })

  let body: any
  try { body = await request.json() } catch { return NextResponse.json({ error: 'Request body required' }, { status: 400 }) }
  const name = body.name

  if (!name || !name.endsWith('.json') || name.includes('/') || name.includes('..') || name.includes('\\')) {
    return NextResponse.json({ error: 'Invalid backup name' }, { status: 400 })
  }

  try {
    const backupPath = join(RLP_BACKUP_DIR, name)
    if (!existsSync(backupPath)) {
      return NextResponse.json({ error: 'Backup not found' }, { status: 404 })
    }

    // Validate it is valid JSON before restoring
    const content = readFileSync(backupPath, 'utf-8')
    JSON.parse(content) // throws if invalid

    // Create a safety backup of current state before restore
    if (existsSync(RLP_STATE_PATH)) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').slice(0, 19)
      ensureDirExists(RLP_BACKUP_DIR)
      copyFileSync(RLP_STATE_PATH, join(RLP_BACKUP_DIR, `rlp-state-pre-restore-${timestamp}.json`))
    }

    copyFileSync(backupPath, RLP_STATE_PATH)

    const ipAddress = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
    logAuditEvent({
      action: 'rlp_backup_restore',
      actor: auth.user.username,
      actor_id: auth.user.id,
      detail: { restored_from: name },
      ip_address: ipAddress,
    })

    return NextResponse.json({ success: true, restored: name })
  } catch (error: any) {
    logger.error({ err: error }, 'RLP backup restore failed')
    return NextResponse.json({ error: `Restore failed: ${error.message}` }, { status: 500 })
  }
}

function pruneOldBackups() {
  try {
    const files = readdirSync(BACKUP_DIR)
      .filter(f => f.startsWith('mc-backup-') && f.endsWith('.db'))
      .map(f => ({ name: f, mtime: statSync(join(BACKUP_DIR, f)).mtimeMs }))
      .sort((a, b) => b.mtime - a.mtime)

    for (const file of files.slice(MAX_BACKUPS)) {
      unlinkSync(join(BACKUP_DIR, file.name))
    }
  } catch {
    // Best-effort pruning
  }
}

function pruneOldRlpBackups() {
  try {
    const files = readdirSync(RLP_BACKUP_DIR)
      .filter(f => f.startsWith('rlp-state-') && f.endsWith('.json'))
      .map(f => ({ name: f, mtime: statSync(join(RLP_BACKUP_DIR, f)).mtimeMs }))
      .sort((a, b) => b.mtime - a.mtime)

    for (const file of files.slice(MAX_BACKUPS)) {
      unlinkSync(join(RLP_BACKUP_DIR, file.name))
    }
  } catch {
    // Best-effort pruning
  }
}
