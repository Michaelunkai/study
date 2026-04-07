import { useEffect } from 'react'

export default function useKeyboardShortcuts({
  onQuickAdd,
  onAddTask,
  onShowHelp,
  onEscape,
  onDeleteTask,
  onToggleFocusMode,
  onNavigate,
}) {
  useEffect(() => {
    const handler = (e) => {
      // Ignore when typing in inputs/textareas
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) return
      if (e.target.isContentEditable) return

      if (e.key === 'Escape') { onEscape?.(); return }
      if (e.key === '?' || (e.key === '/' && e.shiftKey)) { onShowHelp?.(); return }
      if (e.key === 'q' || e.key === 'Q') { onQuickAdd?.(); return }
      if (e.key === 'n' || e.key === 'N') { onAddTask?.(); return }
      if (e.key === 'Delete' || e.key === 'Backspace') { onDeleteTask?.(); return }
      if (e.key === 'f' && (e.ctrlKey || e.metaKey)) { onToggleFocusMode?.(); return }
      if (e.key === 'i') { onNavigate?.('inbox'); return }
      if (e.key === 't') { onNavigate?.('today'); return }
      if (e.key === 'u') { onNavigate?.('upcoming'); return }
      if (e.key === 'p') { onNavigate?.('priority'); return }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onQuickAdd, onAddTask, onShowHelp, onEscape, onDeleteTask, onToggleFocusMode, onNavigate])
}
