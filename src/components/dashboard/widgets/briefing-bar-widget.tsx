'use client'

import { formatTokensShort, type DashboardData } from '../widget-primitives'

export function BriefingBarWidget({ data }: { data: DashboardData }) {
  const {
    isLocal,
    activeSessions,
    onlineAgents,
    runningTasks,
    reviewCount,
    errorCount,
    claudeStats,
    memPct,
    sessions,
    connection,
    isSystemLoading,
    isClaudeLoading,
    subscriptionLabel,
    subscriptionPrice,
    navigateToPanel,
    dbStats,
    agents,
  } = data

  const totalTokens = (claudeStats?.total_input_tokens ?? 0) + (claudeStats?.total_output_tokens ?? 0)
  const costDisplay = subscriptionLabel
    ? (subscriptionPrice ? `$${subscriptionPrice}/mo` : 'Included')
    : `$${(claudeStats?.total_estimated_cost ?? 0).toFixed(2)}`

  const agentTotal = dbStats?.agents.total ?? agents.length

  return (
    <div className="rounded-xl border border-border/70 bg-card/85 backdrop-blur-sm px-4 py-3.5" style={{ boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04), 0 1px 3px rgba(0,0,0,0.3)' }}>
      {/* Top row: key counts */}
      <div className="flex flex-wrap items-center gap-x-6 gap-y-2">
        <BriefingItem
          dot="green"
          onClick={() => navigateToPanel(isLocal ? 'sessions' : 'agents')}
        >
          {isLocal
            ? <><b>{activeSessions}</b> active session{activeSessions !== 1 ? 's' : ''}</>
            : <><b>{onlineAgents}</b>/<b>{agentTotal}</b> agents online</>
          }
        </BriefingItem>

        <BriefingItem
          dot="blue"
          onClick={() => navigateToPanel('tasks')}
        >
          <b>{runningTasks}</b> task{runningTasks !== 1 ? 's' : ''} running
        </BriefingItem>

        {reviewCount > 0 && (
          <BriefingItem
            dot="amber"
            onClick={() => navigateToPanel('tasks')}
          >
            <b>{reviewCount}</b> need{reviewCount === 1 ? 's' : ''} review
          </BriefingItem>
        )}

        {errorCount > 0 && (
          <BriefingItem
            dot="red"
            onClick={() => navigateToPanel('logs')}
          >
            <b>{errorCount}</b> error{errorCount !== 1 ? 's' : ''}
          </BriefingItem>
        )}

        {!isLocal && (
          <BriefingItem dot={connection.isConnected ? 'green' : 'red'}>
            Gateway {connection.isConnected ? 'connected' : 'disconnected'}
            {connection.latency != null && <span className="text-muted-foreground/50 ml-1 font-mono">{connection.latency}ms</span>}
          </BriefingItem>
        )}
      </div>

      {/* Divider */}
      <div className="h-px bg-border/30 my-2" />

      {/* Bottom row: secondary metrics */}
      <div className="flex flex-wrap items-center gap-x-5 gap-y-1 text-[11px] text-muted-foreground/60">
        <span>{sessions.length} session{sessions.length !== 1 ? 's' : ''} today</span>

        {isLocal && !isClaudeLoading && totalTokens > 0 && (
          <span className="font-mono">{formatTokensShort(totalTokens)} tokens</span>
        )}

        {isLocal && !isClaudeLoading && (
          <span className="font-mono">{costDisplay} spent</span>
        )}

        {!isSystemLoading && memPct != null && (
          <span className="inline-flex items-center gap-1.5">
            <span>Memory</span>
            <span className="font-mono font-medium text-muted-foreground/80">{memPct}%</span>
            <span className="inline-flex h-1 w-14 rounded-full bg-secondary/80 overflow-hidden">
              <span
                className={`h-full rounded-full transition-all duration-700 ${
                  memPct > 90 ? 'bg-red-400' : memPct > 70 ? 'bg-amber-400' : 'bg-green-400'
                }`}
                style={{ width: `${Math.min(memPct, 100)}%` }}
              />
            </span>
          </span>
        )}
      </div>
    </div>
  )
}

function BriefingItem({
  dot,
  onClick,
  children,
}: {
  dot: 'green' | 'blue' | 'amber' | 'red'
  onClick?: () => void
  children: React.ReactNode
}) {
  const dotColor = {
    green: 'bg-green-500',
    blue: 'bg-blue-500',
    amber: 'bg-amber-500',
    red: 'bg-red-500',
  }[dot]

  const Tag = onClick ? 'button' : 'span'

  return (
    <Tag
      type={onClick ? 'button' : undefined}
      onClick={onClick}
      className={`inline-flex items-center gap-1.5 text-xs text-foreground/70 transition-all duration-150 rounded-md ${
        onClick ? 'hover:text-foreground cursor-pointer hover:bg-secondary/40 -mx-1.5 px-1.5 py-0.5' : ''
      }`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${dotColor} shrink-0 shadow-[0_0_4px_currentColor]`} />
      <span className="[&>b]:font-semibold [&>b]:text-foreground">{children}</span>
    </Tag>
  )
}
