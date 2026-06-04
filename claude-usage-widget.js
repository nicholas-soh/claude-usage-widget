// Claude Usage Widget
// Scriptable widget — tap to open your Claude usage page
// Install: copy this file into Scriptable, then add as a Small widget

const USAGE_URL = "https://claude.ai/settings/limits"

const BG_COLOR       = new Color("#0f0f0f")
const ACCENT_COLOR   = new Color("#d97706")
const TEXT_COLOR     = Color.white()
const MUTED_COLOR    = new Color("#6b7280")
const SUBTLE_COLOR   = new Color("#374151")

async function createWidget() {
  const widget = new ListWidget()
  widget.backgroundColor = BG_COLOR
  widget.url = USAGE_URL
  widget.setPadding(14, 14, 14, 14)

  // Header row
  const headerStack = widget.addStack()
  headerStack.layoutHorizontally()
  headerStack.centerAlignContent()

  const title = headerStack.addText("Claude")
  title.font = Font.boldSystemFont(17)
  title.textColor = ACCENT_COLOR

  widget.addSpacer(3)

  const subtitle = widget.addText("Monthly Usage")
  subtitle.font = Font.systemFont(11)
  subtitle.textColor = MUTED_COLOR

  widget.addSpacer(10)

  // Month progress
  const now = new Date()
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
  const dayOfMonth  = now.getDate()
  const daysLeft    = daysInMonth - dayOfMonth
  const progress    = dayOfMonth / daysInMonth  // 0–1

  const monthLabel = now.toLocaleString("default", { month: "long", year: "numeric" })
  const monthText  = widget.addText(monthLabel)
  monthText.font   = Font.mediumSystemFont(12)
  monthText.textColor = TEXT_COLOR

  widget.addSpacer(6)

  // Progress bar (drawn as stacked horizontal stacks)
  const BAR_WIDTH   = 120
  const BAR_HEIGHT  = 6
  const filled      = Math.round(BAR_WIDTH * progress)
  const empty       = BAR_WIDTH - filled

  const barStack = widget.addStack()
  barStack.layoutHorizontally()
  barStack.spacing = 0

  if (filled > 0) {
    const filledBox = barStack.addStack()
    filledBox.size = new Size(filled, BAR_HEIGHT)
    filledBox.backgroundColor = ACCENT_COLOR
    filledBox.cornerRadius = 3
  }
  if (empty > 0) {
    const emptyBox = barStack.addStack()
    emptyBox.size = new Size(empty, BAR_HEIGHT)
    emptyBox.backgroundColor = SUBTLE_COLOR
    emptyBox.cornerRadius = 3
  }

  widget.addSpacer(6)

  const daysText = widget.addText(`${daysLeft} day${daysLeft !== 1 ? "s" : ""} left in cycle`)
  daysText.font = Font.systemFont(10)
  daysText.textColor = MUTED_COLOR

  widget.addSpacer(8)

  const cta = widget.addText("Tap to check usage →")
  cta.font = Font.systemFont(10)
  cta.textColor = ACCENT_COLOR

  return widget
}

const widget = await createWidget()

if (config.runsInWidget) {
  Script.setWidget(widget)
} else {
  // Preview when run directly inside Scriptable
  await widget.presentSmall()
}

Script.complete()
