// Claude Usage Widget for Übersicht
// Place this file in: ~/Library/Application Support/Übersicht/widgets/
// Click "Check usage →" to open your Claude usage page

export const refreshFrequency = 60 * 60 * 1000 // refresh every hour

export const command = ""

export const render = () => {
  const now = new Date()
  const year = now.getFullYear()
  const month = now.getMonth()
  const dayOfMonth = now.getDate()
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const daysLeft = daysInMonth - dayOfMonth
  const progress = Math.round((dayOfMonth / daysInMonth) * 100)
  const monthLabel = now.toLocaleString("default", { month: "long", year: "numeric" })

  return (
    <div className="container">
      <div className="header">Claude</div>
      <div className="subtitle">Monthly Usage</div>
      <div className="month">{monthLabel}</div>
      <div className="bar-track">
        <div className="bar-fill" style={{ width: `${progress}%` }} />
      </div>
      <div className="days">{daysLeft} day{daysLeft !== 1 ? "s" : ""} left in cycle</div>
      <a href="https://claude.ai/settings/limits" className="link">Check usage →</a>
    </div>
  )
}

export const className = `
  left: 20px;
  top: 20px;

  .container {
    background: rgba(15, 15, 15, 0.88);
    border-radius: 12px;
    padding: 16px;
    width: 180px;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.07);
  }

  .header {
    color: #d97706;
    font-size: 18px;
    font-weight: 700;
    margin-bottom: 2px;
  }

  .subtitle {
    color: #6b7280;
    font-size: 11px;
    margin-bottom: 12px;
  }

  .month {
    color: #ffffff;
    font-size: 12px;
    font-weight: 500;
    margin-bottom: 8px;
  }

  .bar-track {
    background: #374151;
    border-radius: 4px;
    height: 6px;
    width: 100%;
    margin-bottom: 6px;
    overflow: hidden;
  }

  .bar-fill {
    background: #d97706;
    height: 100%;
    border-radius: 4px;
  }

  .days {
    color: #6b7280;
    font-size: 10px;
    margin-bottom: 12px;
  }

  .link {
    color: #d97706;
    font-size: 10px;
    text-decoration: none;
    display: block;
  }

  .link:hover {
    text-decoration: underline;
  }
`
