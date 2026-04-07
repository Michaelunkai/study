import { useAppContext } from '../context/AppContext'

function formatTime(seconds) {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = (seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

export default function PomodoroTimer({ onExit }) {
  const { timeRemaining } = useAppContext()
  return (
    <div className="fixed inset-0 z-[150] flex flex-col items-center justify-center bg-gray-900/95 backdrop-blur">
      <p className="text-gray-400 text-sm mb-2 uppercase tracking-widest font-medium">Focus Session</p>
      <div className="text-8xl font-mono font-bold text-white mb-8 tabular-nums">
        {formatTime(timeRemaining)}
      </div>
      <button
        onClick={onExit}
        className="px-6 py-2.5 rounded-xl text-sm font-semibold bg-white/10 hover:bg-white/20 text-white transition-colors"
      >
        Exit Focus Mode
      </button>
    </div>
  )
}
