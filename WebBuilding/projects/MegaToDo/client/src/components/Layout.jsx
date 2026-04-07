export default function Layout({ sidebar, children }) {
  return (
    <div className="flex flex-1 overflow-hidden">
      <div className="shrink-0 overflow-y-auto">{sidebar}</div>
      <main className="flex-1 overflow-y-auto">{children}</main>
    </div>
  )
}
