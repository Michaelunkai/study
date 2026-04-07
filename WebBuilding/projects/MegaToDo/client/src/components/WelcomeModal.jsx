export default function WelcomeModal({ user, onComplete }) {
  if (!user || user.onboarding_completed) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl p-8 w-96 max-w-full text-center">
        <div className="text-4xl mb-3">🎉</div>
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">Welcome to MegaToDo!</h2>
        <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Your personal task manager. Press <kbd className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs font-mono">Q</kbd> to quickly add tasks,
          <kbd className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs font-mono mx-1">?</kbd> for all shortcuts.
        </p>
        <button
          onClick={onComplete}
          className="w-full py-2.5 rounded-xl text-sm font-semibold text-white transition-all"
          style={{ backgroundColor: 'var(--color-accent, #7c3aed)' }}
        >
          Get started
        </button>
      </div>
    </div>
  )
}
