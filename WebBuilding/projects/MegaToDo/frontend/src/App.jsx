import { useState, useEffect, useCallback } from 'react'
import { BrowserRouter, Routes, Route, Navigate, NavLink, useNavigate } from 'react-router-dom'
import AuthForm from './components/AuthForm'
import TaskList from './components/TaskList'
import TimeReport from './components/TimeReport'
import FilterBuilder from './components/FilterBuilder'
import ShortcutsModal from './components/ShortcutsModal'
import api from './api'

// ── Icons ────────────────────────────────────────────────────────────────────

function InboxIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>
}
function SunIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
}
function CalendarIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
}
function FolderIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
}
function ClockIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
}
function FilterIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>
}
function MoonIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>
}
function SunSmallIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="6"/><line x1="12" y1="18" x2="12" y2="22"/><line x1="4.93" y1="4.93" x2="7.76" y2="7.76"/><line x1="16.24" y1="16.24" x2="19.07" y2="19.07"/><line x1="2" y1="12" x2="6" y2="12"/><line x1="18" y1="12" x2="22" y2="12"/><line x1="4.93" y1="19.07" x2="7.76" y2="16.24"/><line x1="16.24" y1="7.76" x2="19.07" y2="4.93"/></svg>
}
function LogoutIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
}
function PlusIcon() {
  return <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

function Sidebar({ user, onLogout, dark, onToggleDark, filters, onAddFilter, onFilterClick }) {
  const NAV = [
    { to: '/inbox',    label: 'Inbox',    icon: InboxIcon },
    { to: '/today',    label: 'Today',    icon: SunIcon },
    { to: '/upcoming', label: 'Upcoming', icon: CalendarIcon },
    { to: '/projects', label: 'Projects', icon: FolderIcon },
    { to: '/timelog',  label: 'Time Log', icon: ClockIcon },
  ]

  const navClass = ({ isActive }) =>
    [
      'flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm font-medium transition-colors w-full',
      'focus:outline-none',
      isActive
        ? 'bg-purple-50 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300'
        : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100',
    ].join(' ')

  return (
    <aside className="w-56 shrink-0 bg-gray-50 dark:bg-gray-900 border-r border-gray-200 dark:border-gray-700 flex flex-col py-4 px-2 min-h-screen">
      {/* Header */}
      <div className="px-3 mb-5 flex items-center justify-between">
        <span className="text-base font-extrabold tracking-tight" style={{ color: 'var(--color-accent)' }}>MegaToDo</span>
        <button onClick={onToggleDark} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 p-1 rounded" title="Toggle theme">
          {dark ? <SunSmallIcon /> : <MoonIcon />}
        </button>
      </div>

      {/* User */}
      {user && (
        <div className="px-3 mb-4 flex items-center gap-2">
          <div className="w-7 h-7 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0" style={{ backgroundColor: 'var(--color-accent)' }}>
            {(user.name || user.email || 'U')[0].toUpperCase()}
          </div>
          <span className="text-xs text-gray-600 dark:text-gray-400 truncate flex-1">{user.name || user.email}</span>
        </div>
      )}

      {/* Nav */}
      <nav className="flex-1">
        <ul className="space-y-0.5">
          {NAV.map(({ to, label, icon: Icon }) => (
            <li key={to}>
              <NavLink to={to} className={navClass}>
                <Icon />{label}
              </NavLink>
            </li>
          ))}
        </ul>

        {/* Filters */}
        <div className="mt-5 px-3">
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Filters</span>
            <button onClick={onAddFilter} className="text-gray-400 hover:text-purple-600 p-0.5 rounded" title="Add filter">
              <PlusIcon />
            </button>
          </div>
          {filters.length === 0 && (
            <p className="text-xs text-gray-300 dark:text-gray-600 italic px-1">No filters yet</p>
          )}
          {filters.map(f => (
            <button
              key={f.id}
              onClick={() => onFilterClick(f)}
              className="flex items-center gap-2 w-full px-2 py-1.5 rounded-lg text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              <FilterIcon />{f.name}
            </button>
          ))}
        </div>
      </nav>

      {/* Logout */}
      <div className="pt-4 border-t border-gray-200 dark:border-gray-700 px-2">
        <button
          onClick={onLogout}
          className="flex items-center gap-2 w-full px-3 py-2 rounded-lg text-sm text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-800 dark:hover:text-gray-200 transition-colors"
        >
          <LogoutIcon /> Log out
        </button>
      </div>
    </aside>
  )
}

// ── Page wrappers ────────────────────────────────────────────────────────────

function todayFilter(t) {
  if (!t.due_date) return false
  const d = new Date(t.due_date); d.setHours(0,0,0,0)
  const now = new Date(); now.setHours(0,0,0,0)
  return d <= now
}

function upcomingFilter(t) {
  if (!t.due_date) return false
  const d = new Date(t.due_date); d.setHours(0,0,0,0)
  const now = new Date(); now.setHours(0,0,0,0)
  return d > now
}

function Projects() {
  const [projects, setProjects] = useState([])
  const [selected, setSelected] = useState(null)
  const [newName, setNewName] = useState('')
  const [adding, setAdding] = useState(false)

  useEffect(() => {
    api.get('/api/projects').then(({ data }) => setProjects(data.projects || [])).catch(() => {})
  }, [])

  async function addProject() {
    if (!newName.trim()) return
    const { data } = await api.post('/api/projects', { name: newName.trim(), color: '#7c3aed' })
    setProjects(p => [...p, data])
    setNewName('')
    setAdding(false)
  }

  if (selected) {
    return (
      <div className="flex-1 flex flex-col min-h-0">
        <button
          onClick={() => setSelected(null)}
          className="flex items-center gap-1 mx-6 mt-4 text-sm text-gray-400 hover:text-purple-600 transition-colors"
        >
          ← All Projects
        </button>
        <TaskList projectId={selected.id} title={selected.name} />
      </div>
    )
  }

  return (
    <div className="flex-1 p-6 overflow-y-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-xl font-bold text-gray-900 dark:text-gray-100">Projects</h1>
        <button
          onClick={() => setAdding(true)}
          className="flex items-center gap-1.5 text-sm text-white px-3 py-1.5 rounded-lg"
          style={{ backgroundColor: 'var(--color-accent)' }}
        >
          <PlusIcon /> New Project
        </button>
      </div>

      {adding && (
        <div className="flex gap-2 mb-4">
          <input
            autoFocus
            type="text"
            value={newName}
            onChange={e => setNewName(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') addProject(); if (e.key === 'Escape') setAdding(false) }}
            placeholder="Project name..."
            className="flex-1 px-3 py-2 rounded-lg border border-purple-300 dark:border-purple-700 bg-white dark:bg-gray-800 text-sm text-gray-900 dark:text-gray-100 focus:outline-none"
          />
          <button onClick={addProject} className="px-3 py-2 text-sm text-white rounded-lg" style={{ backgroundColor: 'var(--color-accent)' }}>Add</button>
          <button onClick={() => setAdding(false)} className="px-3 py-2 text-sm text-gray-500 border border-gray-200 dark:border-gray-600 rounded-lg">Cancel</button>
        </div>
      )}

      {projects.length === 0 ? (
        <div className="flex flex-col items-center py-16 text-gray-400">
          <FolderIcon />
          <p className="text-sm mt-2">No projects yet</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-3">
          {projects.map(p => (
            <button
              key={p.id}
              onClick={() => setSelected(p)}
              className="text-left p-4 bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl hover:border-purple-300 dark:hover:border-purple-700 transition-colors"
            >
              <div className="w-8 h-8 rounded-lg mb-2 flex items-center justify-center" style={{ backgroundColor: p.color || '#7c3aed' }}>
                <FolderIcon />
              </div>
              <p className="font-medium text-sm text-gray-800 dark:text-gray-200">{p.name}</p>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

// ── New Task Modal ────────────────────────────────────────────────────────────

function NewTaskModal({ onClose, onCreated }) {
  const [form, setForm] = useState({ title: '', description: '', priority: 4 })
  const [saving, setSaving] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    if (!form.title.trim()) return
    setSaving(true)
    try {
      const { data } = await api.post('/api/tasks', { title: form.title.trim(), description: form.description, priority: form.priority })
      onCreated(data)
      onClose()
    } catch (err) { console.error(err) } finally { setSaving(false) }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl p-6 w-full max-w-md" onClick={e => e.stopPropagation()}>
        <h2 className="text-lg font-bold mb-4 text-gray-900 dark:text-gray-100">New Task</h2>
        <form onSubmit={handleSubmit} className="space-y-3">
          <input
            autoFocus
            type="text"
            value={form.title}
            onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
            placeholder="Task title..."
            className="w-full px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
          <textarea
            value={form.description}
            onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
            placeholder="Description (optional)"
            rows={3}
            className="w-full px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-purple-500 resize-none"
          />
          <select
            value={form.priority}
            onChange={e => setForm(f => ({ ...f, priority: Number(e.target.value) }))}
            className="w-full px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm text-gray-900 dark:text-gray-100"
          >
            <option value={1}>P1 - Urgent</option>
            <option value={2}>P2 - High</option>
            <option value={3}>P3 - Medium</option>
            <option value={4}>P4 - Normal</option>
          </select>
          <div className="flex gap-2 justify-end pt-2">
            <button type="button" onClick={onClose} className="px-4 py-2 text-sm rounded-lg border border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-300">Cancel</button>
            <button type="submit" disabled={saving} className="px-4 py-2 text-sm rounded-lg text-white disabled:opacity-50" style={{ backgroundColor: 'var(--color-accent)' }}>
              {saving ? 'Creating...' : 'Create Task'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ── Main App with keyboard shortcuts ─────────────────────────────────────────

function AppShell({ user, onLogout }) {
  const [dark, setDark] = useState(() => {
    const saved = localStorage.getItem('theme')
    return saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches)
  })
  const [filters, setFilters] = useState([])
  const [showFilterBuilder, setShowFilterBuilder] = useState(false)
  const [showShortcuts, setShowShortcuts] = useState(false)
  const [showNewTask, setShowNewTask] = useState(false)
  const [taskRefreshKey, setTaskRefreshKey] = useState(0)
  const navigate = useNavigate()

  useEffect(() => {
    api.get('/api/filters').then(({ data }) => setFilters(data.filters || [])).catch(() => {})
  }, [])

  function toggleDark() {
    const next = !dark
    document.documentElement.classList.toggle('dark', next)
    localStorage.setItem('theme', next ? 'dark' : 'light')
    setDark(next)
  }

  const handleKey = useCallback((e) => {
    const tag = e.target.tagName
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') {
      if (e.key === 'Escape') {
        e.target.blur()
        setShowNewTask(false)
        setShowShortcuts(false)
        setShowFilterBuilder(false)
      }
      return
    }
    switch (e.key.toLowerCase()) {
      case 't': navigate('/today'); break
      case 'w': navigate('/upcoming'); break
      case 'i': navigate('/inbox'); break
      case 'n': setShowNewTask(true); break
      case '/': {
        e.preventDefault()
        const si = document.getElementById('search-input')
        if (si) si.focus()
        break
      }
      case '?': setShowShortcuts(true); break
      case 'escape':
        setShowNewTask(false)
        setShowShortcuts(false)
        setShowFilterBuilder(false)
        break
      default: break
    }
  }, [navigate])

  useEffect(() => {
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [handleKey])

  function handleFilterClick(f) {
    // Parse query into filter function - simple client-side matching
    navigate('/inbox')
  }

  function reloadFilters() {
    api.get('/api/filters').then(({ data }) => setFilters(data.filters || [])).catch(() => {})
  }

  return (
    <div className="flex min-h-screen bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100">
      <Sidebar
        user={user}
        onLogout={onLogout}
        dark={dark}
        onToggleDark={toggleDark}
        filters={filters}
        onAddFilter={() => setShowFilterBuilder(true)}
        onFilterClick={handleFilterClick}
      />

      <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
        {/* Search bar */}
        <div className="px-6 pt-4 pb-0">
          <input
            id="search-input"
            type="text"
            placeholder="Search tasks... (press /)"
            className="w-full max-w-md px-3 py-1.5 text-sm rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-700 dark:text-gray-300 focus:outline-none focus:ring-2 focus:ring-purple-500 placeholder-gray-400"
          />
        </div>

        <Routes>
          <Route path="/" element={<Navigate to="/inbox" replace />} />
          <Route path="/inbox" element={<TaskList key={`inbox-${taskRefreshKey}`} title="Inbox" />} />
          <Route path="/today" element={<TaskList key={`today-${taskRefreshKey}`} title="Today" filterFn={todayFilter} />} />
          <Route path="/upcoming" element={<TaskList key={`upcoming-${taskRefreshKey}`} title="Upcoming" filterFn={upcomingFilter} />} />
          <Route path="/projects" element={<Projects />} />
          <Route path="/timelog" element={<TimeReport />} />
          <Route path="*" element={<Navigate to="/inbox" replace />} />
        </Routes>
      </div>

      {showFilterBuilder && (
        <FilterBuilder onClose={() => setShowFilterBuilder(false)} onSaved={reloadFilters} />
      )}
      {showShortcuts && (
        <ShortcutsModal onClose={() => setShowShortcuts(false)} />
      )}
      {showNewTask && (
        <NewTaskModal onClose={() => setShowNewTask(false)} onCreated={() => { setShowNewTask(false); setTaskRefreshKey(k => k + 1) }} />
      )}
    </div>
  )
}

// ── Root ─────────────────────────────────────────────────────────────────────

export default function App() {
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('user')) } catch { return null }
  })

  // Initialize dark mode from localStorage or system preference
  useEffect(() => {
    const saved = localStorage.getItem('theme')
    if (saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark')
    }
  }, [])

  function handleAuth(u) {
    setUser(u)
  }

  function handleLogout() {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    setUser(null)
  }

  if (!user) {
    return <AuthForm onAuth={handleAuth} />
  }

  return (
    <BrowserRouter>
      <AppShell user={user} onLogout={handleLogout} />
    </BrowserRouter>
  )
}
