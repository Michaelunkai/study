import { createContext, useContext, useState, useEffect, useRef } from 'react'

const AppContext = createContext()

const WORK_SECONDS = 25 * 60

export function AppProvider({ children }) {
  const [isFocusMode, setIsFocusMode] = useState(false)
  const [timeRemaining, setTimeRemaining] = useState(WORK_SECONDS)
  const intervalRef = useRef(null)

  useEffect(() => {
    if (isFocusMode) {
      setTimeRemaining(WORK_SECONDS)
      intervalRef.current = setInterval(() => {
        setTimeRemaining(t => {
          if (t <= 1) { clearInterval(intervalRef.current); setIsFocusMode(false); return WORK_SECONDS }
          return t - 1
        })
      }, 1000)
    } else {
      clearInterval(intervalRef.current)
      setTimeRemaining(WORK_SECONDS)
    }
    return () => clearInterval(intervalRef.current)
  }, [isFocusMode])

  const toggleFocusMode = () => setIsFocusMode(v => !v)

  return (
    <AppContext.Provider value={{ isFocusMode, toggleFocusMode, timeRemaining }}>
      {children}
    </AppContext.Provider>
  )
}

export function useAppContext() {
  return useContext(AppContext)
}
