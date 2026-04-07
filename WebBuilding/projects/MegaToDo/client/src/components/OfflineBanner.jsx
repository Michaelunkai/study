export default function OfflineBanner({ isOnline }) {
  if (isOnline) return null
  return (
    <div className="bg-yellow-500 text-yellow-900 text-sm font-medium text-center py-1.5 px-4">
      You are offline. Changes may not be saved.
    </div>
  )
}
