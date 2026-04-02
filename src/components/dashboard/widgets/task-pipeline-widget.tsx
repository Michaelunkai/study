'use client'

import type { DashboardData } from '../widget-primitives'

interface PipelineStage {
  label: string
  count: number
  color: string
  bgColor: string
  dotColor: string
}

export function TaskPipelineWidget({ data }: { data: DashboardData }) {
  const { inboxCount, assignedCount, runningTasks, reviewCount, doneCount, navigateToPanel } = data

  const total = inboxCount + assignedCount + runningTasks + reviewCount + doneCount

  const stages: PipelineStage[] = [
    { label: 'Inbox', count: inboxCount, color: 'text-zinc-400', bgColor: 'bg-zinc-500', dotColor: 'bg-zinc-400' },
    { label: 'Assigned', count: assignedCount, color: 'text-blue-400', bgColor: 'bg-blue-500', dotColor: 'bg-blue-400' },
    { label: 'Running', count: runningTasks, color: 'text-amber-400', bgColor: 'bg-amber-500', dotColor: 'bg-amber-400' },
    { label: 'Review', count: reviewCount, color: 'text-purple-400', bgColor: 'bg-purple-500', dotColor: 'bg-purple-400' },
    { label: 'Done', count: doneCount, color: 'text-green-400', bgColor: 'bg-green-500', dotColor: 'bg-green-400' },
  ]

  const hasBottleneck = reviewCount > 3

  if (total === 0) {
    return (
      <div className="panel">
        <div className="panel-header">
          <h3 className="text-sm font-semibold">Task Pipeline</h3>
          <span className="text-2xs text-muted-foreground font-mono-tight">0 tasks</span>
        </div>
        <div
          className="panel-body cursor-pointer hover:bg-secondary/20 transition-smooth rounded-b-lg"
          onClick={() => navigateToPanel('tasks')}
        >
          <p className="text-xs text-muted-foreground/50 text-center py-2">No tasks yet</p>
        </div>
      </div>
    )
  }

  return (
    <div className="panel">
      <div className="panel-header">
        <h3 className="text-sm font-semibold tracking-tight">Task Pipeline</h3>
        <span className="text-[10px] text-muted-foreground/50 font-mono-tight tabular-nums">{total} total</span>
      </div>
      <div
        className="panel-body cursor-pointer hover:bg-secondary/15 transition-all duration-150 rounded-b-xl"
        onClick={() => navigateToPanel('tasks')}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); navigateToPanel('tasks') } }}
        aria-label="Go to task board"
      >
        {/* Progress bar */}
        <div className="flex h-1.5 rounded-full overflow-hidden bg-secondary/40 mb-3.5 gap-px">
          {stages.map((stage) => {
            const pct = total > 0 ? (stage.count / total) * 100 : 0
            if (pct === 0) return null
            return (
              <div
                key={stage.label}
                className={`h-full ${stage.bgColor} transition-all duration-700`}
                style={{ width: `${pct}%`, opacity: stage.label === 'Done' ? 0.8 : 1 }}
                title={`${stage.label}: ${stage.count}`}
              />
            )
          })}
        </div>

        {/* Stage pills */}
        <div className="flex items-center gap-1.5 flex-wrap">
          {stages.map((stage, i) => {
            const hasItems = stage.count > 0
            return (
              <div key={stage.label} className="flex items-center gap-1.5">
                <div className={`inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border transition-all duration-150 ${
                  hasItems
                    ? `${stage.bgColor}/8 border-current/12 ${stage.color}`
                    : 'bg-secondary/20 border-border/15 text-muted-foreground/25'
                }`}>
                  {hasItems && (
                    <span className={`w-1.5 h-1.5 rounded-full ${stage.dotColor} shrink-0 ${
                      stage.label === 'Running' ? 'animate-pulse shadow-[0_0_4px_currentColor]' : ''
                    }`} />
                  )}
                  <span className="text-[11px] font-semibold">{stage.label}</span>
                  <span className={`text-[11px] font-mono-tight font-bold ${hasItems ? 'opacity-90' : 'opacity-30'}`}>
                    {stage.count}
                  </span>
                </div>
                {i < stages.length - 1 && (
                  <svg className="w-2.5 h-2.5 text-muted-foreground/15 shrink-0" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                    <path d="M4 2l4 4-4 4" />
                  </svg>
                )}
              </div>
            )
          })}
        </div>

        {/* Bottleneck warning */}
        {hasBottleneck && (
          <p className="text-[11px] text-amber-400/70 mt-3 flex items-center gap-1.5 font-medium">
            <svg className="w-3.5 h-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
              <path d="M8 2l6.5 11H1.5z" />
              <path d="M8 7v2.5M8 11.5v0" />
            </svg>
            {reviewCount} tasks waiting for review
          </p>
        )}
      </div>
    </div>
  )
}
