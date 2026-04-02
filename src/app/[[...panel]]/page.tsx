'use client'

import { createElement, lazy, Suspense, useEffect, useMemo, useState } from 'react'
import { usePathname, useRouter } from 'next/navigation'
import { NavRail } from '@/components/layout/nav-rail'
import { HeaderBar } from '@/components/layout/header-bar'
import { LiveFeed } from '@/components/layout/live-feed'
import { Dashboard } from '@/components/dashboard/dashboard'
import { ChatPanel } from '@/components/chat/chat-panel'

// Lazily load all panels — they are large and rarely all needed at once
const LogViewerPanel = lazy(() => import('@/components/panels/log-viewer-panel').then(m => ({ default: m.LogViewerPanel })))
const CronManagementPanel = lazy(() => import('@/components/panels/cron-management-panel').then(m => ({ default: m.CronManagementPanel })))
const MemoryBrowserPanel = lazy(() => import('@/components/panels/memory-browser-panel').then(m => ({ default: m.MemoryBrowserPanel })))
const CostTrackerPanel = lazy(() => import('@/components/panels/cost-tracker-panel').then(m => ({ default: m.CostTrackerPanel })))
const TaskBoardPanel = lazy(() => import('@/components/panels/task-board-panel').then(m => ({ default: m.TaskBoardPanel })))
const ActivityFeedPanel = lazy(() => import('@/components/panels/activity-feed-panel').then(m => ({ default: m.ActivityFeedPanel })))
const AgentSquadPanelPhase3 = lazy(() => import('@/components/panels/agent-squad-panel-phase3').then(m => ({ default: m.AgentSquadPanelPhase3 })))
const AgentCommsPanel = lazy(() => import('@/components/panels/agent-comms-panel').then(m => ({ default: m.AgentCommsPanel })))
const StandupPanel = lazy(() => import('@/components/panels/standup-panel').then(m => ({ default: m.StandupPanel })))
const OrchestrationBar = lazy(() => import('@/components/panels/orchestration-bar').then(m => ({ default: m.OrchestrationBar })))
const NotificationsPanel = lazy(() => import('@/components/panels/notifications-panel').then(m => ({ default: m.NotificationsPanel })))
const UserManagementPanel = lazy(() => import('@/components/panels/user-management-panel').then(m => ({ default: m.UserManagementPanel })))
const AuditTrailPanel = lazy(() => import('@/components/panels/audit-trail-panel').then(m => ({ default: m.AuditTrailPanel })))
const WebhookPanel = lazy(() => import('@/components/panels/webhook-panel').then(m => ({ default: m.WebhookPanel })))
const SettingsPanel = lazy(() => import('@/components/panels/settings-panel').then(m => ({ default: m.SettingsPanel })))
const GatewayConfigPanel = lazy(() => import('@/components/panels/gateway-config-panel').then(m => ({ default: m.GatewayConfigPanel })))
const IntegrationsPanel = lazy(() => import('@/components/panels/integrations-panel').then(m => ({ default: m.IntegrationsPanel })))
const AlertRulesPanel = lazy(() => import('@/components/panels/alert-rules-panel').then(m => ({ default: m.AlertRulesPanel })))
const MultiGatewayPanel = lazy(() => import('@/components/panels/multi-gateway-panel').then(m => ({ default: m.MultiGatewayPanel })))
const SuperAdminPanel = lazy(() => import('@/components/panels/super-admin-panel').then(m => ({ default: m.SuperAdminPanel })))
const OfficePanel = lazy(() => import('@/components/panels/office-panel').then(m => ({ default: m.OfficePanel })))
const GitHubSyncPanel = lazy(() => import('@/components/panels/github-sync-panel').then(m => ({ default: m.GitHubSyncPanel })))
const SkillsPanel = lazy(() => import('@/components/panels/skills-panel').then(m => ({ default: m.SkillsPanel })))
const LocalAgentsDocPanel = lazy(() => import('@/components/panels/local-agents-doc-panel').then(m => ({ default: m.LocalAgentsDocPanel })))
const ChannelsPanel = lazy(() => import('@/components/panels/channels-panel').then(m => ({ default: m.ChannelsPanel })))
const DebugPanel = lazy(() => import('@/components/panels/debug-panel').then(m => ({ default: m.DebugPanel })))
const SecurityAuditPanel = lazy(() => import('@/components/panels/security-audit-panel').then(m => ({ default: m.SecurityAuditPanel })))
const NodesPanel = lazy(() => import('@/components/panels/nodes-panel').then(m => ({ default: m.NodesPanel })))
const ExecApprovalPanel = lazy(() => import('@/components/panels/exec-approval-panel').then(m => ({ default: m.ExecApprovalPanel })))
const SystemMonitorPanel = lazy(() => import('@/components/panels/system-monitor-panel').then(m => ({ default: m.SystemMonitorPanel })))
const ChatPagePanel = lazy(() => import('@/components/panels/chat-page-panel').then(m => ({ default: m.ChatPagePanel })))
import { getPluginPanel } from '@/lib/plugins'
import { shouldRedirectDashboardToHttps } from '@/lib/browser-security'
import { useTranslations } from 'next-intl'
import { ErrorBoundary } from '@/components/ErrorBoundary'
import { LocalModeBanner } from '@/components/layout/local-mode-banner'
import { UpdateBanner } from '@/components/layout/update-banner'
import { OpenClawUpdateBanner } from '@/components/layout/openclaw-update-banner'
import { OpenClawDoctorBanner } from '@/components/layout/openclaw-doctor-banner'
import { OnboardingWizard } from '@/components/onboarding/onboarding-wizard'
import { Loader } from '@/components/ui/loader'
import { ProjectManagerModal } from '@/components/modals/project-manager-modal'
import { ExecApprovalOverlay } from '@/components/modals/exec-approval-overlay'
import { useWebSocket } from '@/lib/websocket'
import { useServerEvents } from '@/lib/use-server-events'
import { completeNavigationTiming } from '@/lib/navigation-metrics'
import { panelHref, useNavigateToPanel } from '@/lib/navigation'
import { clearOnboardingDismissedThisSession, clearOnboardingReplayFromStart, getOnboardingSessionDecision, markOnboardingReplayFromStart, readOnboardingDismissedThisSession } from '@/lib/onboarding-session'
import { Button } from '@/components/ui/button'
import { useMissionControl } from '@/store'

interface GatewaySummary {
  id: number
  is_primary: number
}

const STEP_KEYS = ['auth', 'capabilities', 'config', 'connect', 'agents', 'sessions', 'projects', 'memory', 'skills'] as const

const bootLabelKeys: Record<string, string> = {
  auth: 'authenticatingOperator',
  capabilities: 'detectingStationMode',
  config: 'loadingControlConfig',
  connect: 'connectingRuntimeLinks',
  agents: 'syncingAgentRegistry',
  sessions: 'loadingActiveSessions',
  projects: 'hydratingWorkspaceBoard',
  memory: 'mappingMemoryGraph',
  skills: 'indexingSkillCatalog',
}

function renderPluginPanel(panelId: string) {
  const pluginPanel = getPluginPanel(panelId)
  return pluginPanel ? createElement(pluginPanel) : <Dashboard />
}

export default function Home() {
  const router = useRouter()
  const { connect } = useWebSocket()
  const tb = useTranslations('boot')
  const tp = useTranslations('page')
  const tc = useTranslations('common')
  const { activeTab, setActiveTab, setCurrentUser, setDashboardMode, setGatewayAvailable, setLocalSessionsAvailable, setCapabilitiesChecked, setSubscription, setDefaultOrgName, setUpdateAvailable, setOpenclawUpdate, showOnboarding, setShowOnboarding, liveFeedOpen, toggleLiveFeed, showProjectManagerModal, setShowProjectManagerModal, fetchProjects, setChatPanelOpen, bootComplete, setBootComplete, setAgents, setSessions, setProjects, setInterfaceMode, setMemoryGraphAgents, setSkillsData } = useMissionControl()

  // Sync URL → Zustand activeTab
  const pathname = usePathname()
  const panelFromUrl = pathname === '/' ? 'overview' : pathname.slice(1)
  const normalizedPanel = panelFromUrl === 'sessions' ? 'chat' : panelFromUrl

  useEffect(() => {
    completeNavigationTiming(pathname)
  }, [pathname])

  useEffect(() => {
    completeNavigationTiming(panelHref(activeTab))
  }, [activeTab])

  useEffect(() => {
    setActiveTab(normalizedPanel)
    if (normalizedPanel === 'chat') {
      setChatPanelOpen(false)
    }
    if (panelFromUrl === 'sessions') {
      router.replace('/chat')
    }
  }, [panelFromUrl, normalizedPanel, router, setActiveTab, setChatPanelOpen])

  // Connect to SSE for real-time local DB events (tasks, agents, chat, etc.)
  useServerEvents()
  const [isClient, setIsClient] = useState(false)
  const [stepStatuses, setStepStatuses] = useState<Record<string, 'pending' | 'done'>>(
    () => Object.fromEntries(STEP_KEYS.map(k => [k, 'pending']))
  )

  const initSteps = useMemo(() =>
    STEP_KEYS.map(key => ({
      key,
      label: tb(bootLabelKeys[key] as Parameters<typeof tb>[0]),
      status: stepStatuses[key] || 'pending' as const,
    })),
    [tb, stepStatuses]
  )

  const markStep = (key: string) => {
    setStepStatuses(prev => ({ ...prev, [key]: 'done' }))
  }

  useEffect(() => {
    if (!bootComplete && initSteps.every(s => s.status === 'done')) {
      setBootComplete()
    }
  }, [initSteps, bootComplete, setBootComplete])

  // Security console warning (anti-self-XSS)
  useEffect(() => {
    if (!bootComplete) return
    if (typeof window === 'undefined') return
    const key = 'mc-console-warning'
    if (sessionStorage.getItem(key)) return
    sessionStorage.setItem(key, '1')

    console.log(
      '%c  Stop!  ',
      'color: #fff; background: #e53e3e; font-size: 40px; font-weight: bold; padding: 4px 16px; border-radius: 4px;'
    )
    console.log(
      '%cThis is a browser feature intended for developers.\n\nIf someone told you to copy-paste something here to enable a feature or "hack" an account, it is a scam and will give them access to your account.',
      'font-size: 14px; color: #e2e8f0; padding: 8px 0;'
    )
    console.log(
      '%cLearn more: https://en.wikipedia.org/wiki/Self-XSS',
      'font-size: 12px; color: #718096;'
    )
  }, [bootComplete])

  useEffect(() => {
    setIsClient(true)

    if (shouldRedirectDashboardToHttps({
      protocol: window.location.protocol,
      hostname: window.location.hostname,
      forceHttps: process.env.NEXT_PUBLIC_FORCE_HTTPS === '1',
    })) {
      const secureUrl = new URL(window.location.href)
      secureUrl.protocol = 'https:'
      window.location.replace(secureUrl.toString())
      return
    }

    const connectWithEnvFallback = () => {
      const explicitWsUrl = process.env.NEXT_PUBLIC_GATEWAY_URL || ''
      const gatewayPort = process.env.NEXT_PUBLIC_GATEWAY_PORT || '18789'
      const gatewayHost = process.env.NEXT_PUBLIC_GATEWAY_HOST || window.location.hostname
      const gatewayProto =
        process.env.NEXT_PUBLIC_GATEWAY_PROTOCOL ||
        (window.location.protocol === 'https:' ? 'wss' : 'ws')
      const wsUrl = explicitWsUrl || `${gatewayProto}://${gatewayHost}:${gatewayPort}`
      connect(wsUrl)
    }

    const connectWithPrimaryGateway = async (): Promise<{ attempted: boolean; connected: boolean }> => {
      try {
        const gatewaysRes = await fetch('/api/gateways')
        if (!gatewaysRes.ok) return { attempted: false, connected: false }
        const gatewaysJson = await gatewaysRes.json().catch(() => ({}))
        const gateways = Array.isArray(gatewaysJson?.gateways) ? gatewaysJson.gateways as GatewaySummary[] : []
        if (gateways.length === 0) return { attempted: false, connected: false }

        const primaryGateway = gateways.find(gw => Number(gw?.is_primary) === 1) || gateways[0]
        if (!primaryGateway?.id) return { attempted: true, connected: false }

        const connectRes = await fetch('/api/gateways/connect', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: primaryGateway.id }),
        })
        if (!connectRes.ok) return { attempted: true, connected: false }

        const payload = await connectRes.json().catch(() => ({}))
        const wsUrl = typeof payload?.ws_url === 'string' ? payload.ws_url : ''
        const wsToken = typeof payload?.token === 'string' ? payload.token : ''
        if (!wsUrl) return { attempted: true, connected: false }

        connect(wsUrl, wsToken)
        return { attempted: true, connected: true }
      } catch {
        return { attempted: false, connected: false }
      }
    }

    // Fetch current user
    fetch('/api/auth/me')
      .then(async (res) => {
        if (res.ok) return res.json()
        if (res.status === 401) {
          router.replace(`/login?next=${encodeURIComponent(pathname)}`)
        }
        return null
      })
      .then(data => { if (data?.user) setCurrentUser(data.user); markStep('auth') })
      .catch(() => { markStep('auth') })

    // Check for available updates
    fetch('/api/releases/check')
      .then(res => res.ok ? res.json() : null)
      .then(data => {
        if (data?.updateAvailable) {
          setUpdateAvailable({
            latestVersion: data.latestVersion,
            releaseUrl: data.releaseUrl,
            releaseNotes: data.releaseNotes,
          })
        }
      })
      .catch(() => {})

    // Check for OpenClaw updates
    fetch('/api/openclaw/version')
      .then(res => res.ok ? res.json() : null)
      .then(data => {
        if (data?.updateAvailable) {
          setOpenclawUpdate({
            installed: data.installed,
            latest: data.latest,
            releaseUrl: data.releaseUrl,
            releaseNotes: data.releaseNotes,
            updateCommand: data.updateCommand,
          })
        } else {
          setOpenclawUpdate(null)
        }
      })
      .catch(() => {})

    // Check capabilities, then conditionally connect to gateway
    fetch('/api/status?action=capabilities')
      .then(res => res.ok ? res.json() : null)
      .then(async data => {
        if (data?.subscription) {
          setSubscription(data.subscription)
        }
        if (data?.processUser) {
          setDefaultOrgName(data.processUser)
        }
        if (data?.interfaceMode === 'essential' || data?.interfaceMode === 'full') {
          setInterfaceMode(data.interfaceMode)
        }
        if (data && data.gateway === false) {
          setDashboardMode('local')
          setGatewayAvailable(false)
          setCapabilitiesChecked(true)
          markStep('capabilities')
          markStep('connect')
          // Skip WebSocket connect — no gateway to talk to
          return
        }
        if (data && data.gateway === true) {
          setDashboardMode('full')
          setGatewayAvailable(true)
        }
        if (data?.claudeHome) {
          setLocalSessionsAvailable(true)
        }
        setCapabilitiesChecked(true)
        markStep('capabilities')

        const primaryConnect = await connectWithPrimaryGateway()
        if (!primaryConnect.connected && !primaryConnect.attempted) {
          connectWithEnvFallback()
        }
        markStep('connect')
      })
      .catch(() => {
        // If capabilities check fails, still try to connect
        setCapabilitiesChecked(true)
        markStep('capabilities')
        markStep('connect')
        connectWithEnvFallback()
      })

    // Check onboarding state
    fetch('/api/onboarding')
      .then(res => res.ok ? res.json() : null)
      .then(data => {
        const decision = getOnboardingSessionDecision({
          isAdmin: data?.isAdmin === true,
          serverShowOnboarding: data?.showOnboarding === true,
          completed: data?.completed === true,
          skipped: data?.skipped === true,
          dismissedThisSession: readOnboardingDismissedThisSession(),
        })

        if (decision.shouldOpen) {
          clearOnboardingDismissedThisSession()
          if (decision.replayFromStart) {
            markOnboardingReplayFromStart()
          } else {
            clearOnboardingReplayFromStart()
          }
          setShowOnboarding(true)
        }
        markStep('config')
      })
      .catch(() => { markStep('config') })
    // Preload workspace data in parallel
    Promise.allSettled([
      fetch('/api/agents')
        .then(r => r.ok ? r.json() : null)
        .then((agentsData) => {
          if (agentsData?.agents) setAgents(agentsData.agents)
        })
        .finally(() => { markStep('agents') }),
      // Sessions can be slow with many JSONL files — don't block boot
      (() => {
        markStep('sessions')
        return fetch('/api/sessions')
          .then(r => r.ok ? r.json() : null)
          .then((sessionsData) => {
            if (sessionsData?.sessions) setSessions(sessionsData.sessions)
          })
      })(),
      fetch('/api/projects')
        .then(r => r.ok ? r.json() : null)
        .then((projectsData) => {
          if (projectsData?.projects) setProjects(projectsData.projects)
        })
        .finally(() => { markStep('projects') }),
      // Memory graph can be slow — don't block boot
      (() => {
        markStep('memory')
        return fetch('/api/memory/graph?agent=all')
          .then(r => r.ok ? r.json() : null)
          .then((graphData) => {
            if (graphData?.agents) setMemoryGraphAgents(graphData.agents)
          })
      })(),
      fetch('/api/skills')
        .then(r => r.ok ? r.json() : null)
        .then((skillsData) => {
          if (skillsData?.skills) setSkillsData(skillsData.skills, skillsData.groups || [], skillsData.total || 0)
        })
        .finally(() => { markStep('skills') }),
    ]).catch(() => { /* panels will lazy-load as fallback */ })

  // eslint-disable-next-line react-hooks/exhaustive-deps -- boot once on mount, not on every pathname change
  }, [connect, router, setCurrentUser, setDashboardMode, setGatewayAvailable, setLocalSessionsAvailable, setCapabilitiesChecked, setSubscription, setUpdateAvailable, setShowOnboarding, setAgents, setSessions, setProjects, setInterfaceMode, setMemoryGraphAgents, setSkillsData])

  if (!isClient || !bootComplete) {
    return <Loader variant="page" steps={isClient ? initSteps : undefined} />
  }

  return (
    <div className="flex h-screen h-screen-dvh bg-background overflow-hidden no-overflow-x">
      <a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:top-2 focus:left-2 focus:px-4 focus:py-2 focus:bg-primary focus:text-primary-foreground focus:rounded-md focus:text-sm focus:font-medium">
        {tc('skipToMainContent')}
      </a>

      {/* Left: Icon rail navigation (hidden on mobile, shown as bottom bar instead) */}
      {!showOnboarding && <NavRail />}

      {/* Center: Header + Content */}
      <div className="flex-1 flex flex-col min-w-0">
        {!showOnboarding && (
          <>
            <HeaderBar />
            <LocalModeBanner />
            <UpdateBanner />
            <OpenClawUpdateBanner />
            <OpenClawDoctorBanner />
          </>
        )}
        <main
          id="main-content"
          className={`flex-1 overflow-auto pb-16 md:pb-0 ${showOnboarding ? 'pointer-events-none select-none blur-[2px] opacity-30' : ''}`}
          role="main"
          aria-hidden={showOnboarding}
        >
          <div aria-live="polite" className="flex flex-col min-h-full">
            <ErrorBoundary key={activeTab}>
              <ContentRouter tab={activeTab} />
            </ErrorBoundary>
          </div>
{/* Footer removed — attribution moved to nav sidebar */}
        </main>
      </div>

      {/* Right: Live feed (hidden on mobile) */}
      {!showOnboarding && liveFeedOpen && (
        <div className="hidden lg:flex h-full">
          <LiveFeed />
        </div>
      )}

      {/* Floating button to reopen LiveFeed when closed */}
      {!showOnboarding && !liveFeedOpen && (
        <button
          onClick={toggleLiveFeed}
          className="hidden lg:flex fixed right-0 top-1/2 -translate-y-1/2 z-30 w-6 h-12 items-center justify-center bg-card border border-r-0 border-border rounded-l-md text-muted-foreground hover:text-foreground hover:bg-secondary transition-all duration-200"
          title={tp('showLiveFeed')}
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
            <path d="M10 3l-5 5 5 5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      )}

      {/* Chat panel overlay */}
      {!showOnboarding && <ChatPanel />}

      {/* Global exec approval overlay (shown regardless of active panel) */}
      {!showOnboarding && <ExecApprovalOverlay />}

      {/* Global Project Manager Modal */}
      {!showOnboarding && showProjectManagerModal && (
        <ProjectManagerModal
          onClose={() => setShowProjectManagerModal(false)}
          onChanged={async () => { await fetchProjects() }}
        />
      )}

      <OnboardingWizard />
    </div>
  )
}

const ESSENTIAL_PANELS = new Set([
  'overview', 'agents', 'tasks', 'chat', 'activity', 'logs', 'settings',
])

function ContentRouter({ tab }: { tab: string }) {
  const tp = useTranslations('page')
  const { dashboardMode, interfaceMode, setInterfaceMode } = useMissionControl()
  const navigateToPanel = useNavigateToPanel()
  const isLocal = dashboardMode === 'local'
  const panelName = tab.replace(/-/g, ' ')

  // Guard: show nudge for non-essential panels in essential mode
  if (interfaceMode === 'essential' && !ESSENTIAL_PANELS.has(tab)) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center gap-4">
        <p className="text-sm text-muted-foreground">
          {tp('availableInFullMode', { panel: panelName })}
        </p>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={async () => {
              setInterfaceMode('full')
              try { await fetch('/api/settings', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ settings: { 'general.interface_mode': 'full' } }) }) } catch {}
            }}
          >
            {tp('switchToFull')}
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigateToPanel('overview')}
          >
            {tp('goToOverview')}
          </Button>
        </div>
      </div>
    )
  }

  const panelFallback = <div className="flex items-center justify-center py-24"><div className="w-6 h-6 border-2 border-primary/30 border-t-primary rounded-full animate-spin" /></div>

  let content: React.ReactNode
  switch (tab) {
    case 'overview':
      content = (
        <>
          <Dashboard />
          {!isLocal && (
            <div className="mt-4 mx-4 mb-4 rounded-lg border border-border bg-card overflow-hidden">
              <AgentCommsPanel />
            </div>
          )}
        </>
      )
      break
    case 'tasks':
      content = <TaskBoardPanel />
      break
    case 'agents':
      content = (
        <>
          <OrchestrationBar />
          {isLocal && <LocalAgentsDocPanel />}
          <AgentSquadPanelPhase3 />
        </>
      )
      break
    case 'notifications':
      content = <NotificationsPanel />
      break
    case 'standup':
      content = <StandupPanel />
      break
    case 'sessions':
      content = <ChatPagePanel />
      break
    case 'logs':
      content = <LogViewerPanel />
      break
    case 'cron':
      content = <CronManagementPanel />
      break
    case 'memory':
      content = <MemoryBrowserPanel />
      break
    case 'cost-tracker':
    case 'tokens':
    case 'agent-costs':
      content = <CostTrackerPanel />
      break
    case 'users':
      content = <UserManagementPanel />
      break
    case 'history':
    case 'activity':
      content = <ActivityFeedPanel />
      break
    case 'audit':
      content = <AuditTrailPanel />
      break
    case 'webhooks':
      content = <WebhookPanel />
      break
    case 'alerts':
      content = <AlertRulesPanel />
      break
    case 'gateways':
      content = isLocal ? <LocalModeUnavailable panel={tab} /> : <MultiGatewayPanel />
      break
    case 'gateway-config':
      content = isLocal ? <LocalModeUnavailable panel={tab} /> : <GatewayConfigPanel />
      break
    case 'integrations':
      content = <IntegrationsPanel />
      break
    case 'settings':
      content = <SettingsPanel />
      break
    case 'super-admin':
      content = <SuperAdminPanel />
      break
    case 'github':
      content = <GitHubSyncPanel />
      break
    case 'office':
      content = <OfficePanel />
      break
    case 'monitor':
      content = <SystemMonitorPanel />
      break
    case 'skills':
      content = <SkillsPanel />
      break
    case 'channels':
      content = isLocal ? <LocalModeUnavailable panel={tab} /> : <ChannelsPanel />
      break
    case 'nodes':
      content = isLocal ? <LocalModeUnavailable panel={tab} /> : <NodesPanel />
      break
    case 'security':
      content = <SecurityAuditPanel />
      break
    case 'debug':
      content = <DebugPanel />
      break
    case 'exec-approvals':
      content = isLocal ? <LocalModeUnavailable panel={tab} /> : <ExecApprovalPanel />
      break
    case 'chat':
      content = <ChatPagePanel />
      break
    default:
      content = renderPluginPanel(tab)
  }

  return <Suspense fallback={panelFallback}>{content}</Suspense>
}

function LocalModeUnavailable({ panel }: { panel: string }) {
  const tp = useTranslations('page')
  return (
    <div className="flex flex-col items-center justify-center py-24 text-center">
      <p className="text-sm text-muted-foreground">
        {tp('requiresGateway', { panel })}
      </p>
      <p className="text-xs text-muted-foreground mt-1">
        {tp('configureGateway')}
      </p>
    </div>
  )
}
