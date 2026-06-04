# Claude Usage Widget for Scriptable

A macOS/iOS widget that shows your current billing cycle progress and links directly to your Claude usage page.

![Widget preview: dark background, amber "Claude" title, month progress bar, days remaining, tap-to-open link](preview.png)

## Features

- Shows current month and billing cycle progress bar
- Displays days remaining in the cycle
- Tap to open [claude.ai/settings/limits](https://claude.ai/settings/limits) directly
- Dark theme matching Claude's aesthetic

## Installation

1. Install [Scriptable](https://apps.apple.com/app/scriptable/id1405459188) (free) from the Mac App Store or iOS App Store.
2. Copy the contents of `claude-usage-widget.js` into a new script in Scriptable.
3. Name the script **Claude Usage Widget**.
4. On macOS: right-click the desktop → **Edit Widgets** → find Scriptable → add a **Small** widget → configure it to use **Claude Usage Widget**.
5. On iOS: long-press the home screen → **+** → Scriptable → Small → select **Claude Usage Widget**.

## Usage

- The progress bar fills as the month progresses (time-based, not usage-based — Claude doesn't expose live usage data via a public API).
- Tap the widget to jump straight to your Claude usage page.
- To see your actual usage %, check [claude.ai/settings/limits](https://claude.ai/settings/limits).

## Customization

Edit the color constants at the top of the script:

```js
const ACCENT_COLOR = new Color("#d97706")  // amber — change to any hex
const BG_COLOR     = new Color("#0f0f0f")  // near-black background
```

## License

MIT
