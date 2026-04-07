import { useState, useEffect, useCallback } from 'react'
import AuthForm from './components/AuthForm'
import TopBar from './components/TopBar'
import QuickAddTask from './components/QuickAddTask'
import ShortcutsHelpModal from './components/ShortcutsHelpModal'
import WelcomeModal from './components/WelcomeModal'
import OfflineBanner from './components/OfflineBanner'
import PomodoroTimer from './components/PomodoroTimer'
import Layout from './components/Layout'
import Sidebar from './components/Sidebar'
import InboxView from './views/InboxView'
import UpcomingView from './views/UpcomingView'
import PriorityView from './views/PriorityView'
import useKeyboardShortcuts from './hooks/useKeyboardShortcuts'
import { useOfflineDetector } from './hooks/useOfflineDetector'
import { AppProvider, useAppContext } from './context/AppContext'
import { ThemeProvider, useTheme } from './context/ThemeContext'
import './App.css'

const API_BASE = ''
const WORK_SECONDS = 25 * 60

// Inner component — has access to AppContext
function AppInner() {
  const { isOnline } = useOfflineDetector()
  const { isDark: darkMode, toggleTheme } = useTheme()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [quickAddOpen, setQuickAddOpen] = useState(false)
  const [shortcutsHelpOpen, setShortcutsHelpOpen] = useState(false)
  const [toastMessage, setToastMessage] = useState('')
  const [tasks, setTasks] = useState([])
  const [activeView, setActiveView] = useState('inbox')
  const [activeProjectId, setActiveProjectId] = useState(null)
  const [token, setToken] = useState(() => localStorage.getItem('token') || null)
  const [user, setUser] = useState(
    () => {
      const saved = localStorage.getItem('user_onboarding')
      if (saved === 'completed') return { onboarding_completed: true }
      return { onboarding_completed: false }
    }
  )

  // Pull focus mode + pomodoro state from context
  const {
    isFocusMode,
    toggleFocusMode,
    timeRemaining,
  } = useAppContext()

  const handleLogin = (newToken, userData) => {
    localStorage.setItem('token', newToken)
    if (userData) localStorage.setItem('megatodo_user', JSON.stringify(userData))
    setToken(newToken)
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('megatodo_user')
    setToken(null)
    setTasks([])
    setProjects([])
  }

  const showToast = (message) => {
    setToastMessage(message)
    setTimeout(() => setToastMessage(''), 2000)
  }

  const [projects, setProjects] = useState([])

  const fetchTasks = useCallback(async () => {
    try {
      const headers = {}
      if (token) headers['Authorization'] = `Bearer ${token}`
      const res = await fetch(`${API_BASE}/api/tasks`, { headers })
      if (res.ok) {
        const data = await res.json()
        setTasks(Array.isArray(data) ? data : (data.tasks || []))
      }
    } catch (err) {
      console.error('Failed to fetch tasks:', err)
    }
  }, [token])

  const fetchProjects = useCallback(async () => {
    try {
      const headers = {}
      if (token) headers['Authorization'] = `Bearer ${token}`
      const res = await fetch(`${API_BASE}/api/projects`, { headers })
      if (res.ok) {
        const data = await res.json()
        setProjects(Array.isArray(data) ? data : (data.projects || []))
      }
    } catch (err) {
      console.error('Failed to fetch projects:', err)
    }
  }, [token])

  useEffect(() => {
    fetchTasks()
    fetchProjects()
  }, [fetchTasks, fetchProjects])

  const handleQuickAddSubmit = async (taskData) => {
    try {
      const payload = typeof taskData === 'string'
        ? { title: taskData }
        : taskData
      const res = await fetch(`${API_BASE}/api/tasks`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify(payload),
      })
      if (res.ok) {
        setQuickAddOpen(false)
        fetchTasks()
        showToast('Task added!')
      } else {
        showToast('Failed to add task')
      }
    } catch (err) {
      console.error('Error adding task:', err)
      showToast('Error adding task')
    }
  }

  useKeyboardShortcuts({
    onQuickAdd: () => setQuickAddOpen((prev) => !prev),
    onAddTask: () => setQuickAddOpen(true),
    onShowHelp: () => setShortcutsHelpOpen(true),
    onEscape: () => {
      if (shortcutsHelpOpen) { setShortcutsHelpOpen(false); return }
      if (quickAddOpen) { setQuickAddOpen(false); return }
    },
    onDeleteTask: () => showToast('Select a task first to delete it'),
    onToggleFocusMode: toggleFocusMode,
    onNavigate: (view) => setActiveView(view),
  })

  const toggleSidebar = () => setSidebarOpen((prev) => !prev)
  const handleSearch = (query) => { setSearchQuery(query) }
  const handleAddTask = () => { setQuickAddOpen(true) }
  const toggleDark = toggleTheme
  const handleSearchNavigate = ({ type, item }) => {
    showToast(`Navigating to ${type}: ${item.title || item.name}`)
  }

  // Timer strip progress (0–1): how far through the 25-min work block
  const timerProgress = Math.max(0, Math.min(1, 1 - timeRemaining / WORK_SECONDS))

  if (!token) {
    return <AuthForm onLogin={handleLogin} />
  }

  return (
    <div className="flex flex-col min-h-screen bg-white dark:bg-gray-900">
      {/* Pomodoro timer strip — fixed top strip when Focus Mode is active */}
      {isFocusMode && (
        <div
          className="fixed top-0 left-0 right-0 z-[200] h-1 bg-gray-200 dark:bg-gray-700"
          role="progressbar"
          aria-valuenow={Math.round(timerProgress * 100)}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-label="Pomodoro timer progress"
        >
          <div
            className="h-full bg-red-500 transition-all duration-1000 ease-linear"
            style={{ width: `${timerProgress * 100}%` }}
          />
        </div>
      )}

      <OfflineBanner isOnline={isOnline} />
      {!isFocusMode && (
        <TopBar
          onToggleSidebar={toggleSidebar}
          onSearch={handleSearch}
          onAddTask={handleAddTask}
          onToggleDark={toggleDark}
          onToggleFocusMode={toggleFocusMode}
          onSearchNavigate={handleSearchNavigate}
          isFocusMode={isFocusMode}
          darkMode={darkMode}
          sidebarOpen={sidebarOpen}
        />
      )}
      <Layout
        sidebar={
          <Sidebar
            activeProjectId={activeProjectId}
            onSelectProject={(project) => {
              setActiveProjectId(project.id)
              setActiveView('project')
            }}
            token={token}
          />
        }
      >
        <div className={`flex-1 overflow-y-auto${isFocusMode ? ' max-w-2xl mx-auto w-full' : ''}`}>
          {activeView === 'inbox' && <InboxView token={token} />}
          {activeView === 'upcoming' && <UpcomingView token={token} />}
          {activeView === 'priority' && <PriorityView token={token} />}
          {activeView === 'project' && activeProjectId && (
            <InboxView token={token} projectId={activeProjectId} />
          )}
        </div>
      </Layout>

      {/* PomodoroTimer overlay — shown when Focus Mode is active */}
      {isFocusMode && (
        <PomodoroTimer onExit={toggleFocusMode} />
      )}

      {/* QuickAddTask modal — triggered by Q key, + key, or the + Add Task button */}
      <QuickAddTask
        isOpen={quickAddOpen}
        onClose={() => setQuickAddOpen(false)}
        onTaskAdded={() => { fetchTasks(); showToast('Task added!') }}
        projects={projects}
      />

      <ShortcutsHelpModal
        isOpen={shortcutsHelpOpen}
        onClose={() => setShortcutsHelpOpen(false)}
      />

      <WelcomeModal
        user={user}
        onComplete={() => {
          localStorage.setItem('user_onboarding', 'completed')
          setUser({ onboarding_completed: true })
        }}
      />

      {/* Focus Mode exit button — shown when NOT using the full PomodoroTimer overlay */}
      {isFocusMode && (
        <button
          onClick={toggleFocusMode}
          className="fixed top-4 right-4 z-50 flex items-center gap-1 text-sm px-3 py-1.5 rounded-full bg-gray-800 text-white opacity-50 hover:opacity-100 transition-opacity duration-200"
          aria-label="Exit Focus Mode"
        >
          Exit Focus <span aria-hidden="true">&#x2715;</span>
        </button>
      )}

      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-[100] bg-green-600 text-white text-sm font-medium px-4 py-2 rounded-lg shadow-lg">
          {toastMessage}
        </div>
      )}
    </div>
  )
}

function App() {
  return (
    <ThemeProvider>
      <AppProvider>
        <AppInner />
      </AppProvider>
    </ThemeProvider>
  )
}

export default App
