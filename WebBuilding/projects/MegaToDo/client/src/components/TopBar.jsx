import { useState } from 'react'

function MenuIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
}
function PlusIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
}
function MoonIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>
}
function SunIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
}
function SearchIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
}
function FocusIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg>
}

export default function TopBar({
  onToggleSidebar,
  onSearch,
  onAddTask,
  onToggleDark,
  onToggleFocusMode,
  onSearchNavigate,
  isFocusMode,
  darkMode,
  sidebarOpen,
}) {
  const [query, setQuery] = useState('')

  const handleSearch = (e) => {
    const val = e.target.value
    setQuery(val)
    onSearch?.(val)
  }

  return (
    <header className="h-12 flex items-center gap-2 px-3 border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shrink-0">
      <button
        onClick={onToggleSidebar}
        className="p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
        aria-label="Toggle sidebar"
      >
        <MenuIcon />
      </button>

      <span className="font-extrabold text-sm tracking-tight mr-2" style={{ color: 'var(--color-accent, #7c3aed)' }}>
        MegaToDo
      </span>

      <div className="flex-1 flex items-center gap-1.5 max-w-md bg-gray-100 dark:bg-gray-800 rounded-lg px-3 py-1.5">
        <SearchIcon />
        <input
          type="text"
          value={query}
          onChange={handleSearch}
          placeholder="Search tasks... (Press / to focus)"
          className="flex-1 bg-transparent text-sm text-gray-700 dark:text-gray-300 placeholder-gray-400 outline-none"
        />
      </div>

      <div className="flex items-center gap-1 ml-auto">
        <button
          onClick={onToggleFocusMode}
          className={`p-1.5 rounded-lg transition-colors ${isFocusMode ? 'text-red-500 bg-red-50 dark:bg-red-900/20' : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-700 dark:hover:text-gray-300'}`}
          aria-label="Toggle focus mode"
          title="Focus mode (Ctrl+F)"
        >
          <FocusIcon />
        </button>
        <button
          onClick={onToggleDark}
          className="p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
          aria-label="Toggle dark mode"
        >
          {darkMode ? <SunIcon /> : <MoonIcon />}
        </button>
        <button
          onClick={onAddTask}
          className="flex items-center gap-1.5 ml-1 px-3 py-1.5 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: 'var(--color-accent, #7c3aed)' }}
          aria-label="Add task"
        >
          <PlusIcon /> Add task
        </button>
      </div>
    </header>
  )
}
