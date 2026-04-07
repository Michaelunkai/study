'use client'

import { Button } from '@/components/ui/button'

export interface DbStats {
  tasks: { total: number; byStatus: Record<string, number> }
  agents: { total: number; byStatus: Record<string, number> }
  audit: { day: number; week: number; loginFailures: number }
  activities: { day: number }
  notifications: { unread: number }
  pipelines: { active: number; recentDay: number }
  backup: { name: string; size: number; age_hours: number } | null
  dbSizeBytes: number
  webhookCount: number
}

export interface ClaudeStats {
  total_sessions: number
  active_sessions: number
  total_input_tokens: number
  total_output_tokens: number
  total_estimated_cost: number
  unique_projects: number
}

export type LogLike = {
  id: string
  timestamp: number
  level: 'info' | 'warn' | 'error' | 'debug'
  source: string
  message: string
}

export interface DashboardData {
  isLocal: boolean
  systemStats: any
  dbStats: DbStats | null
  claudeStats: ClaudeStats | null
  githubStats: any
  loading: { system: boolean; sessions: boolean; claude: boolean; github: boolean }
  sessions: any[]
  logs: any[]
  agents: any[]
  tasks: any[]
  connection: { isConnected: boolean; url: string; reconnectAttempts: number; latency?: number; sseConnected?: boolean }
  subscription: { type: string; provider?: string; rateLimitTier?: string } | null
  navigateToPanel: (tab: string) => void
  openSession: (session: any) => void
  // Pre-computed values
  memPct: number | null
  diskPct: number
  systemLoad: number
  activeSessions: number
  errorCount: number
  onlineAgents: number
  claudeActive: number
  codexActive: number
  hermesActive: number
  claudeLocalSessions: any[]
  codexLocalSessions: any[]
  hermesLocalSessions: any[]
  runningTasks: number
  inboxCount: number
  assignedCount: number
  reviewCount: number
  doneCount: number
  backlogCount: number
  mergedRecentLogs: LogLike[]
  recentErrorLogs: number
  // Health statuses
  localOsStatus: { value: string; status: 'good' | 'warn' | 'bad' }
  claudeHealth: { value: string; status: 'good' | 'warn' | 'bad' }
  codexHealth: { value: string; status: 'good' | 'warn' | 'bad' }
  hermesHealth: { value: string; status: 'good' | 'warn' | 'bad' }
  mcHealth: { value: string; status: 'good' | 'warn' | 'bad' }
  gatewayHealthStatus: 'good' | 'bad'
  // Loading states
  isSystemLoading: boolean
  isSessionsLoading: boolean
  isClaudeLoading: boolean
  isGithubLoading: boolean
  // Hermes enrichment
  hermesCronJobCount: number
  // Subscription display
  subscriptionLabel: string | null
  subscriptionPrice: number | null
}

// --- Sub-components ---

export function MetricCard({ label, value, total, subtitle, icon, color }: {
  label: string
  value: number | string
  total?: number
  subtitle?: string
  icon: React.ReactNode
  color: 'blue' | 'green' | 'purple' | 'red'
}) {
  const colorMap = {
    blue: {
      container: 'bg-blue-500/8 text-blue-400 border-blue-500/18',
      iconBg: 'bg-blue-500/15 text-blue-300',
      bar: 'bg-blue-500/40',
    },
    green: {
      container: 'bg-green-500/8 text-green-400 border-green-500/18',
      iconBg: 'bg-green-500/15 text-green-300',
      bar: 'bg-green-500/40',
    },
    purple: {
      container: 'bg-purple-500/8 text-purple-400 border-purple-500/18',
      iconBg: 'bg-purple-500/15 text-purple-300',
      bar: 'bg-purple-500/40',
    },
    red: {
      container: 'bg-red-500/8 text-red-400 border-red-500/18',
      iconBg: 'bg-red-500/15 text-red-300',
      bar: 'bg-red-500/40',
    },
  }

  const c = colorMap[color]

  return (
    <div className={`rounded-xl border p-4 transition-all duration-200 ${c.container}`} style={{ boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)' }}>
      <div className="flex items-start justify-between mb-3">
        <span className="text-xs font-semibold uppercase tracking-wider opacity-60">{label}</span>
        <div className={`w-7 h-7 rounded-lg flex items-center justify-center ${c.iconBg}`}>
          <div className="w-4 h-4">{icon}</div>
        </div>
      </div>
      <div className="flex items-baseline gap-1.5">
        <span className="text-[1.75rem] font-bold font-mono-tight leading-none tracking-tight">{value}</span>
        {total != null && <span className="text-sm opacity-40 font-mono-tight">/ {total}</span>}
      </div>
      {subtitle && <div className="text-[11px] opacity-45 font-mono-tight mt-1.5 truncate">{subtitle}</div>}
    </div>
  )
}

export function SignalPill({ label, value, tone }: {
  label: string
  value: string
  tone: 'success' | 'warning' | 'info'
}) {
  const toneClass = tone === 'success'
    ? 'bg-green-500/12 border-green-500/25 text-green-300'
    : tone === 'warning'
      ? 'bg-amber-500/12 border-amber-500/25 text-amber-300'
      : 'bg-blue-500/12 border-blue-500/25 text-blue-300'

  const dotClass = tone === 'success'
    ? 'bg-green-400'
    : tone === 'warning'
      ? 'bg-amber-400'
      : 'bg-blue-400'

  return (
    <div className={`rounded-xl border px-3 py-2.5 transition-all duration-150 hover:brightness-110 ${toneClass}`} style={{ boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)' }}>
      <div className="flex items-center gap-1.5 mb-0.5">
        <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${dotClass}`} />
        <div className="text-[10px] uppercase tracking-wider font-semibold opacity-55">{label}</div>
      </div>
      <div className="text-xs font-semibold font-mono-tight truncate">{value}</div>
    </div>
  )
}

export function HealthRow({ label, value, status, bar }: {
  label: string
  value: string
  status: 'good' | 'warn' | 'bad'
  bar?: number
}) {
  const statusConfig = {
    good: { text: 'text-green-400', dot: 'bg-green-400', bar: 'bg-green-400' },
    warn: { text: 'text-amber-400', dot: 'bg-amber-400', bar: 'bg-amber-400' },
    bad: { text: 'text-red-400', dot: 'bg-red-400', bar: 'bg-red-400' },
  }
  const sc = statusConfig[status]

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-1.5 min-w-0">
          <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${sc.dot}`} />
          <span className="text-xs text-muted-foreground/70 truncate">{label}</span>
        </div>
        <span className={`text-xs font-semibold font-mono-tight ${sc.text} shrink-0`}>{value}</span>
      </div>
      {bar != null && (
        <div className="h-1 rounded-full bg-secondary/60 overflow-hidden">
          <div
            className={`h-full rounded-full transition-all duration-700 ${bar > 90 ? 'bg-red-400' : bar > 70 ? 'bg-amber-400' : 'bg-green-400'}`}
            style={{ width: `${Math.min(bar, 100)}%` }}
          />
        </div>
      )}
    </div>
  )
}

export function StatRow({ label, value, alert }: { label: string; value: number | string; alert?: boolean }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-xs text-muted-foreground">{label}</span>
      <span className={`text-xs font-medium font-mono-tight ${alert ? 'text-red-400' : 'text-muted-foreground'}`}>
        {value}
      </span>
    </div>
  )
}

export function LogRow({ log }: { log: LogLike }) {
  const levelConfig = {
    error: { dot: 'bg-red-400', bg: 'hover:bg-red-500/5', label: 'text-red-400/60' },
    warn: { dot: 'bg-amber-400', bg: 'hover:bg-amber-500/5', label: 'text-amber-400/60' },
    debug: { dot: 'bg-gray-400/50', bg: 'hover:bg-secondary/20', label: 'text-muted-foreground/40' },
    info: { dot: 'bg-blue-400/60', bg: 'hover:bg-secondary/20', label: 'text-blue-400/40' },
  }
  const config = levelConfig[log.level] ?? levelConfig.info

  return (
    <div className={`px-4 py-2.5 transition-all duration-100 ${config.bg}`}>
      <div className="flex items-start gap-2.5">
        <div className={`w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 ${config.dot} ${log.level === 'error' ? 'shadow-[0_0_4px_currentColor]' : ''}`} />
        <div className="flex-1 min-w-0">
          <p className="text-xs text-foreground/75 break-words leading-relaxed">{log.message.length > 100 ? log.message.slice(0, 100) + '...' : log.message}</p>
          <div className="flex items-center gap-1.5 mt-0.5">
            <span className={`text-[10px] font-mono-tight font-semibold uppercase tracking-wider ${config.label}`}>{log.source}</span>
            <span className="text-[10px] text-muted-foreground/25">·</span>
            <span className="text-[10px] text-muted-foreground/40 font-mono-tight">{new Date(log.timestamp).toLocaleTimeString()}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export function QuickAction({ label, desc, tab, icon, onNavigate }: {
  label: string
  desc: string
  tab: string
  icon: React.ReactNode
  onNavigate: (tab: string) => void
}) {
  return (
    <Button
      variant="outline"
      onClick={() => onNavigate(tab)}
      className="flex items-center gap-3 p-3.5 h-auto rounded-xl hover:border-primary/25 hover:bg-primary/5 text-left group justify-start transition-all duration-150"
    >
      <div className="w-9 h-9 rounded-xl bg-secondary/60 flex items-center justify-center shrink-0 group-hover:bg-primary/12 transition-all duration-150">
        <div className="w-4 h-4 text-muted-foreground/60 group-hover:text-primary transition-all duration-150">{icon}</div>
      </div>
      <div>
        <div className="text-xs font-semibold text-foreground">{label}</div>
        <div className="text-[11px] text-muted-foreground/55 mt-0.5">{desc}</div>
      </div>
    </Button>
  )
}

// --- Helper functions ---

export function formatUptime(ms: number): string {
  const hours = Math.floor(ms / (1000 * 60 * 60))
  const days = Math.floor(hours / 24)
  if (days > 0) return `${days}d ${hours % 24}h`
  return `${hours}h`
}

export function formatTokensShort(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${Math.round(n / 1_000)}K`
  return String(n)
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`
}

export function getProviderHealth(active: number, total: number): { value: string; status: 'good' | 'warn' | 'bad' } {
  if (total === 0) return { value: 'No sessions', status: 'warn' }
  if (active > 0) return { value: `${active} active`, status: 'good' }
  return { value: `Idle (${total})`, status: 'warn' }
}

export function getLocalOsStatus(memPct: number | null, diskPct: number | null): { value: string; status: 'good' | 'warn' | 'bad' } {
  if (memPct == null && diskPct == null) return { value: 'Unknown', status: 'bad' }
  const maxPct = Math.max(memPct ?? 0, diskPct ?? 0)
  if (maxPct >= 95) return { value: 'Critical', status: 'bad' }
  if (maxPct >= 80) return { value: 'Degraded', status: 'warn' }
  return { value: 'Healthy', status: 'good' }
}

export function getMcHealth(systemStats: any, dbStats: DbStats | null, errorCount: number): { value: string; status: 'good' | 'warn' | 'bad' } {
  if (!systemStats || !dbStats) return { value: 'Unavailable', status: 'bad' }
  if (errorCount > 0) return { value: `${errorCount} errors`, status: 'warn' }
  return { value: 'Healthy', status: 'good' }
}

// --- SVG Icons ---

export function SessionIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <path d="M2 3h12v9H2zM5 12v2M11 12v2M4 14h8" />
    </svg>
  )
}

export function AgentIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <circle cx="8" cy="5" r="3" />
      <path d="M2 14c0-3.3 2.7-6 6-6s6 2.7 6 6" />
    </svg>
  )
}

export function GatewayIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <path d="M2 8h3M11 8h3M5 5l3-3 3 3M5 11l3 3 3-3" />
      <circle cx="8" cy="8" r="2" />
    </svg>
  )
}

export function ActivityIconMini() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <path d="M2 9h2l1.4-3.5L8.2 12l2-5H14" />
    </svg>
  )
}

export function TaskIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <rect x="2" y="1" width="12" height="14" rx="1.5" />
      <path d="M5 5h6M5 8h6M5 11h3" />
    </svg>
  )
}

export function SpawnActionIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <path d="M8 2v12M8 2l-3 3M8 2l3 3" />
    </svg>
  )
}

export function LogActionIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <path d="M3 2h10a1 1 0 011 1v10a1 1 0 01-1 1H3a1 1 0 01-1-1V3a1 1 0 011-1z" />
      <path d="M5 5h6M5 8h6M5 11h3" />
    </svg>
  )
}

export function TaskActionIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <rect x="2" y="1" width="12" height="14" rx="1.5" />
      <path d="M5 5l2 2 3-3" />
      <path d="M5 10h6" />
    </svg>
  )
}

export function MemoryActionIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <ellipse cx="8" cy="8" rx="6" ry="3" />
      <path d="M2 8v3c0 1.7 2.7 3 6 3s6-1.3 6-3V8" />
    </svg>
  )
}

export function PipelineActionIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <circle cx="3" cy="8" r="2" />
      <circle cx="13" cy="4" r="2" />
      <circle cx="13" cy="12" r="2" />
      <path d="M5 7l6-2M5 9l6 2" />
    </svg>
  )
}

export function TokenIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <circle cx="8" cy="8" r="6" />
      <path d="M8 4v8M5 6h6M5 10h6" />
    </svg>
  )
}

export function CostIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
      <circle cx="8" cy="8" r="6" />
      <path d="M8 3.5V5M8 11v1.5M10.5 6.5C10.5 5.4 9.4 4.5 8 4.5S5.5 5.4 5.5 6.5c0 1.1 1.1 2 2.5 2s2.5.9 2.5 2c0 1.1-1.1 2-2.5 2s-2.5-.9-2.5-2" />
    </svg>
  )
}
