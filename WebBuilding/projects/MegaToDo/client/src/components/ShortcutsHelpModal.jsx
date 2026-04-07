export default function ShortcutsHelpModal({ isOpen, onClose }) {
  if (!isOpen) return null
  const shortcuts = [
    ['Q', 'Toggle quick add task'],
    ['N', 'New task'],
    ['I', 'Go to Inbox'],
    ['T', 'Go to Today'],
    ['U', 'Go to Upcoming'],
    ['P', 'Go to Priority'],
    ['Ctrl+F', 'Toggle focus mode'],
    ['?', 'Show shortcuts'],
    ['Esc', 'Close modal'],
  ]
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl p-6 w-80 max-w-full" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">Keyboard shortcuts</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 text-xl leading-none">&times;</button>
        </div>
        <dl className="space-y-2">
          {shortcuts.map(([key, desc]) => (
            <div key={key} className="flex items-center justify-between gap-4">
              <dt><kbd className="px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-xs font-mono font-medium">{key}</kbd></dt>
              <dd className="text-sm text-gray-600 dark:text-gray-400">{desc}</dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  )
}
