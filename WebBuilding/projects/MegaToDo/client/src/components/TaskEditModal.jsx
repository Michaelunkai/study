import { useState } from 'react'

const API_BASE = ''

function getAuthHeaders(extra = {}) {
  const token = localStorage.getItem('token')
  return token ? { Authorization: `Bearer ${token}`, ...extra } : { ...extra }
}

export default function TaskEditModal({ task, onClose, onSave }) {
  const [title, setTitle] = useState(task.title || '')
  const [description, setDescription] = useState(task.description || '')
  const [due_date, setDueDate] = useState(task.due_date ? task.due_date.slice(0, 10) : '')
  const [priority, setPriority] = useState(task.priority || 1)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const save = async () => {
    if (!title.trim()) { setError('Title is required'); return }
    setSaving(true)
    try {
      const res = await fetch(`${API_BASE}/api/tasks/${task.id}`, {
        method: 'PUT',
        headers: getAuthHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ title: title.trim(), description, due_date: due_date || null, priority }),
      })
      if (res.ok) {
        onSave()
      } else {
        const data = await res.json()
        setError(data.error || 'Failed to save')
      }
    } catch {
      setError('Network error')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl p-6 w-full max-w-md" onClick={e => e.stopPropagation()}>
        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Edit Task</h2>
        <div className="space-y-3">
          <input
            type="text"
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="Task title"
            className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
          <textarea
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="Description (optional)"
            rows={3}
            className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500 resize-none"
          />
          <div className="flex gap-3">
            <input
              type="date"
              value={due_date}
              onChange={e => setDueDate(e.target.value)}
              className="flex-1 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
            <select
              value={priority}
              onChange={e => setPriority(Number(e.target.value))}
              className="flex-1 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
            >
              <option value={1}>P1 — Urgent</option>
              <option value={2}>P2 — High</option>
              <option value={3}>P3 — Medium</option>
              <option value={4}>P4 — Low</option>
            </select>
          </div>
          {error && <p className="text-sm text-red-500">{error}</p>}
        </div>
        <div className="flex justify-end gap-2 mt-5">
          <button onClick={onClose} className="px-4 py-2 rounded-lg text-sm font-medium text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">Cancel</button>
          <button
            onClick={save}
            disabled={saving}
            className="px-4 py-2 rounded-lg text-sm font-semibold text-white transition-colors disabled:opacity-60"
            style={{ backgroundColor: 'var(--color-accent, #7c3aed)' }}
          >
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  )
}
