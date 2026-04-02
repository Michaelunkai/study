'use client'

import Image from 'next/image'
import { useCallback, useEffect, useRef, useState } from 'react'
import { useMissionControl } from '@/store'
import { useNavigateToPanel } from '@/lib/navigation'
import { createClientLogger } from '@/lib/client-logger'
import { Button } from '@/components/ui/button'

const log = createClientLogger('Sidebar')

type SystemStats = {
  memory?: {
    used: number
    total: number
  }
  disk?: {
    usage?: string
  }
  processes?: unknown[]
}

function readSystemStats(value: unknown): SystemStats | null {
  if (!value || typeof value !== 'object') return null
  const record = value as Record<string, unknown>
  const memory = record.memory && typeof record.memory === 'object' ? record.memory as Record<string, unknown> : null
  const disk = record.disk && typeof record.disk === 'object' ? record.disk as Record<string, unknown> : null

  return {
    memory: memory && typeof memory.used === 'number' && typeof memory.total === 'number'
      ? { used: memory.used, total: memory.total }
      : undefined,
    disk: disk
      ? { usage: typeof disk.usage === 'string' ? disk.usage : undefined }
      : undefined,
    processes: Array.isArray(record.processes) ? record.processes : undefined,
  }
}

interface MenuItem {
  id: string
  label: string
  icon: string
  description?: string
}

const defaultMenuItems: MenuItem[] = [
  { id: 'overview', label: 'Overview', icon: '📊', description: 'System dashboard' },
  { id: 'chat', label: 'Chat', icon: '💬', description: 'Agent chat sessions' },
  { id: 'tasks', label: 'Task Board', icon: '📋', description: 'Kanban task management' },
  { id: 'agents', label: 'Agent Squad', icon: '🤖', description: 'Agent management & status' },
  { id: 'activity', label: 'Activity Feed', icon: '📣', description: 'Real-time activity stream' },
  { id: 'notifications', label: 'Notifications', icon: '🔔', description: 'Mentions & alerts' },
  { id: 'standup', label: 'Daily Standup', icon: '📈', description: 'Generate standup reports' },
  { id: 'spawn', label: 'Spawn Agent', icon: '🚀', description: 'Launch new sub-agents' },
  { id: 'logs', label: 'Logs', icon: '📝', description: 'Real-time log viewer' },
  { id: 'cron', label: 'Cron Jobs', icon: '⏰', description: 'Automated tasks' },
  { id: 'memory', label: 'Memory', icon: '🧠', description: 'Knowledge browser' },
  { id: 'tokens', label: 'Tokens', icon: '💰', description: 'Usage & cost tracking' },
  { id: 'channels', label: 'Channels', icon: '📡', description: 'Messaging platform status' },
  { id: 'nodes', label: 'Nodes', icon: '🖥', description: 'Connected instances' },
  { id: 'exec-approvals', label: 'Approvals', icon: '✅', description: 'Exec approval queue' },
  { id: 'debug', label: 'Debug', icon: '🐛', description: 'System diagnostics' },
]

type ValidationStatus = 'idle' | 'running' | 'pass' | 'fail'

interface ValidationResult {
  status: ValidationStatus
  message: string
  checkedAt?: string
}

const MENU_ORDER_KEY = 'mc-sidebar-menu-order'

function loadMenuOrder(): MenuItem[] {
  if (typeof window === 'undefined') return defaultMenuItems
  try {
    const saved = localStorage.getItem(MENU_ORDER_KEY)
    if (!saved) return defaultMenuItems
    const ids: string[] = JSON.parse(saved)
    const itemMap = new Map(defaultMenuItems.map(i => [i.id, i]))
    const ordered = ids.map(id => itemMap.get(id)).filter(Boolean) as MenuItem[]
    // append any new items not in saved order
    const missing = defaultMenuItems.filter(i => !ids.includes(i.id))
    return [...ordered, ...missing]
  } catch {
    return defaultMenuItems
  }
}

export function Sidebar() {
  const { activeTab, connection, sessions } = useMissionControl()
  const navigateToPanel = useNavigateToPanel()
  const [systemStats, setSystemStats] = useState<SystemStats | null>(null)
  const [menuItems, setMenuItems] = useState<MenuItem[]>(defaultMenuItems)
  const [validations, setValidations] = useState<Record<string, ValidationResult>>({})
  const [validationModal, setValidationModal] = useState<{ id: string; label: string } | null>(null)
  const validationTimers = useRef<Record<string, ReturnType<typeof setTimeout>>>({})

  // Load saved order after mount (avoids SSR mismatch)
  useEffect(() => {
    setMenuItems(loadMenuOrder())
  }, [])

  useEffect(() => {
    let cancelled = false
    fetch('/api/status?action=overview')
      .then(res => res.json())
      .then(data => { if (!cancelled) setSystemStats(readSystemStats(data)) })
      .catch(err => log.error('Failed to fetch system status:', err))
    return () => { cancelled = true }
  }, [])

  const saveOrder = useCallback((items: MenuItem[]) => {
    try {
      localStorage.setItem(MENU_ORDER_KEY, JSON.stringify(items.map(i => i.id)))
    } catch { /* ignore */ }
  }, [])

  const moveUp = useCallback((index: number) => {
    if (index === 0) return
    setMenuItems(prev => {
      const next = [...prev]
      ;[next[index - 1], next[index]] = [next[index], next[index - 1]]
      saveOrder(next)
      return next
    })
  }, [saveOrder])

  const moveDown = useCallback((index: number) => {
    setMenuItems(prev => {
      if (index >= prev.length - 1) return prev
      const next = [...prev]
      ;[next[index], next[index + 1]] = [next[index + 1], next[index]]
      saveOrder(next)
      return next
    })
  }, [saveOrder])

  const validateMission = useCallback(async (item: MenuItem) => {
    const id = item.id
    // Show modal immediately
    setValidationModal({ id, label: item.label })
    setValidations(prev => ({ ...prev, [id]: { status: 'running', message: 'Validating...' } }))

    // Clear any existing timer
    if (validationTimers.current[id]) {
      clearTimeout(validationTimers.current[id])
    }

    try {
      // Attempt to call the panel's API endpoint for validation
      const controller = new AbortController()
      const timeout = setTimeout(() => controller.abort(), 8000)
      const panelEndpoints: Record<string, string> = {
        overview: '/api/status?action=overview',
        agents: '/api/agents',
        tasks: '/api/tasks',
        logs: '/api/logs',
        cron: '/api/cron',
        memory: '/api/memory',
        tokens: '/api/tokens',
        channels: '/api/channels',
        nodes: '/api/nodes',
        'exec-approvals': '/api/exec-approvals',
        activity: '/api/activities',
        notifications: '/api/notifications',
        standup: '/api/status?action=overview',
        spawn: '/api/agents',
        debug: '/api/diagnostics',
        chat: '/api/chat',
      }
      const endpoint = panelEndpoints[id] || `/api/status?action=${id}`
      const res = await fetch(endpoint, { signal: controller.signal })
      clearTimeout(timeout)
      const checkedAt = new Date().toLocaleTimeString()
      if (res.ok) {
        setValidations(prev => ({ ...prev, [id]: { status: 'pass', message: `Panel is reachable (HTTP ${res.status})`, checkedAt } }))
      } else {
        setValidations(prev => ({ ...prev, [id]: { status: 'fail', message: `Panel returned HTTP ${res.status}`, checkedAt } }))
      }
    } catch (err) {
      const checkedAt = new Date().toLocaleTimeString()
      const msg = err instanceof Error && err.name === 'AbortError' ? 'Validation timed out after 8s' : 'Panel unreachable'
      setValidations(prev => ({ ...prev, [id]: { status: 'fail', message: msg, checkedAt } }))
    }

    // Auto-dismiss modal after 4s
    validationTimers.current[id] = setTimeout(() => {
      setValidationModal(null)
    }, 4000)
  }, [])

  const activeSessions = sessions.filter(s => s.active).length
  const totalSessions = sessions.length

  const validationStatusColor: Record<ValidationStatus, string> = {
    idle: 'text-muted-foreground',
    running: 'text-yellow-500',
    pass: 'text-green-500',
    fail: 'text-red-500',
  }

  const currentValidation = validationModal ? validations[validationModal.id] : null

  return (
    <aside className="w-64 bg-card border-r border-border flex flex-col">
      {/* Logo/Brand */}
      <div className="p-6 border-b border-border">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-lg overflow-hidden bg-background border border-border/50 flex items-center justify-center">
            <Image
              src="/brand/mc-logo-128.png"
              alt="Mission Control logo"
              width={32}
              height={32}
              className="w-full h-full object-cover"
            />
          </div>
          <div>
            <h2 className="font-bold text-foreground">Mission Control</h2>
            <p className="text-xs text-muted-foreground">ClawdBot Orchestration</p>
          </div>
        </div>
      </div>

      {/* Validation Modal */}
      {validationModal && currentValidation && (
        <div className="mx-3 mt-3 mb-0 p-3 rounded-lg border bg-secondary/80 shadow-sm">
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs font-semibold text-foreground truncate max-w-[160px]">
              Validating: {validationModal.label}
            </span>
            <button
              onClick={() => setValidationModal(null)}
              className="text-muted-foreground hover:text-foreground text-xs leading-none ml-2"
              title="Dismiss"
            >
              x
            </button>
          </div>
          <div className={`text-xs font-medium ${validationStatusColor[currentValidation.status]}`}>
            {currentValidation.status === 'running' && (
              <span className="inline-block animate-spin mr-1">⟳</span>
            )}
            {currentValidation.status === 'pass' && '✓ '}
            {currentValidation.status === 'fail' && '✗ '}
            {currentValidation.message}
          </div>
          {currentValidation.checkedAt && (
            <div className="text-xs text-muted-foreground mt-0.5">Checked at {currentValidation.checkedAt}</div>
          )}
        </div>
      )}

      {/* Navigation */}
      <nav className="flex-1 p-4 overflow-y-auto">
        <ul className="space-y-1">
          {menuItems.map((item, index) => {
            const val = validations[item.id]
            const isActive = activeTab === item.id
            return (
              <li key={item.id} className="group/item relative">
                <div className="flex items-center gap-1">
                  {/* Main nav button */}
                  <Button
                    variant={isActive ? 'default' : 'ghost'}
                    onClick={() => navigateToPanel(item.id)}
                    className={`flex-1 flex items-start space-x-3 px-3 py-3 h-auto rounded-lg text-left justify-start group ${
                      isActive ? 'shadow-sm' : ''
                    }`}
                    title={item.description}
                  >
                    <span className="text-lg mt-0.5">{item.icon}</span>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium flex items-center gap-1">
                        {item.label}
                        {val && val.status !== 'idle' && (
                          <span className={`text-xs ${validationStatusColor[val.status]}`} title={val.message}>
                            {val.status === 'running' ? '⟳' : val.status === 'pass' ? '✓' : '✗'}
                          </span>
                        )}
                      </div>
                      <div className={`text-xs mt-0.5 ${
                        isActive
                          ? 'text-primary-foreground/80'
                          : 'text-muted-foreground group-hover:text-foreground/70'
                      }`}>
                        {item.description}
                      </div>
                    </div>
                  </Button>

                  {/* Action buttons - visible on hover */}
                  <div className="flex flex-col gap-0.5 opacity-0 group-hover/item:opacity-100 transition-opacity">
                    {/* Up arrow */}
                    <button
                      onClick={(e) => { e.stopPropagation(); moveUp(index) }}
                      disabled={index === 0}
                      className="w-5 h-5 flex items-center justify-center rounded text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-20 disabled:cursor-not-allowed text-xs leading-none"
                      title="Move up"
                    >
                      ▲
                    </button>
                    {/* Validate (X check) */}
                    <button
                      onClick={(e) => { e.stopPropagation(); validateMission(item) }}
                      className="w-5 h-5 flex items-center justify-center rounded text-muted-foreground hover:text-foreground hover:bg-accent text-xs font-bold leading-none"
                      title={`Validate ${item.label}`}
                    >
                      {validations[item.id]?.status === 'running' ? '⟳' : '✕'}
                    </button>
                    {/* Down arrow */}
                    <button
                      onClick={(e) => { e.stopPropagation(); moveDown(index) }}
                      disabled={index === menuItems.length - 1}
                      className="w-5 h-5 flex items-center justify-center rounded text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-20 disabled:cursor-not-allowed text-xs leading-none"
                      title="Move down"
                    >
                      ▼
                    </button>
                  </div>
                </div>
              </li>
            )
          })}
        </ul>
      </nav>

      {/* Status Footer */}
      <div className="p-4 border-t border-border space-y-3">
        {/* Connection Status */}
        <div className="bg-secondary rounded-lg p-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-foreground">Gateway</span>
            <div className="flex items-center space-x-1">
              <div className={`w-2 h-2 rounded-full ${
                connection.isConnected 
                  ? 'bg-green-500 animate-pulse' 
                  : 'bg-red-500'
              }`}></div>
              <span className="text-xs text-muted-foreground">
                {connection.isConnected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
          </div>
            <div className="mt-2 space-y-1">
              <div className="text-xs text-muted-foreground">
                {connection.url || 'ws://<gateway-host>:<gateway-port>'}
              </div>
              {connection.latency && (
                <div className="text-xs text-muted-foreground">
                  Latency: {connection.latency}ms
                </div>
            )}
          </div>
        </div>

        {/* Session Stats */}
        <div className="bg-secondary rounded-lg p-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-foreground">Sessions</span>
            <span className="text-xs text-muted-foreground">
              {activeSessions}/{totalSessions}
            </span>
          </div>
          <div className="mt-2 text-xs text-muted-foreground">
            {activeSessions} active • {totalSessions - activeSessions} idle
          </div>
        </div>

        {/* System Stats */}
        {systemStats && (
          <div className="bg-secondary rounded-lg p-3">
            <div className="text-sm font-medium text-foreground mb-2">System</div>
            <div className="space-y-1 text-xs text-muted-foreground">
              <div className="flex justify-between">
                <span>Memory:</span>
                <span>{systemStats.memory ? Math.round((systemStats.memory.used / systemStats.memory.total) * 100) : 0}%</span>
              </div>
              <div className="flex justify-between">
                <span>Disk:</span>
                <span>{systemStats.disk?.usage || 'N/A'}</span>
              </div>
              <div className="flex justify-between">
                <span>Processes:</span>
                <span>{systemStats.processes?.length || 0}</span>
              </div>
            </div>
          </div>
        )}
      </div>
    </aside>
  )
}
