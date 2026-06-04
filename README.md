# Claude Usage Widget for Übersicht

A macOS desktop widget that shows your current billing cycle progress and links directly to your Claude usage page.

## Features

- Shows current month and billing cycle progress bar
- Displays days remaining in the cycle
- Click "Check usage →" to open [claude.ai/settings/limits](https://claude.ai/settings/limits) directly
- Dark frosted-glass theme

## Installation

1. Download and install [Übersicht](https://tracesof.net/uebersicht/) (free, not on the App Store — download from the website).
2. Open Übersicht — it will create a widgets folder automatically.
3. Copy `claude-usage-widget.jsx` into `~/Library/Application Support/Übersicht/widgets/`.
4. The widget appears on your desktop immediately.

To move the widget, edit the `left` and `top` values at the top of the `className` block:

```js
export const className = `
  left: 20px;   /* distance from left edge */
  top: 20px;    /* distance from top edge */
  ...
`
```

## Usage

- The progress bar fills as the month progresses (time-based, not usage-based — Claude doesn't expose live usage data via a public API).
- Click the widget link to jump straight to your Claude usage page.
- The widget refreshes every hour automatically.

## Customization

Edit the color values in the `className` block:

```js
color: #d97706;     /* amber accent — change to any hex */
background: rgba(15, 15, 15, 0.88);  /* background opacity */
```

## License

MIT
