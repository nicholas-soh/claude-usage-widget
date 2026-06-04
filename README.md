# Claude Usage Widget for xbar

A macOS menu bar plugin that shows your **real** Claude spend % — pulled live from the Claude API — with colour-coded thresholds.

## What it looks like

```
☁ 30%   ← live spend % in your menu bar

Clicking opens a dropdown:
─────────────────────────────
Claude Usage — June 2026
─────────────────────────────
███░░░░░░░  30%
$X,XXX of $XX,XXX USD used
─────────────────────────────
Open Usage Page
Refresh
```

When no claude.ai tab is open, the last known value is shown with a `↻` indicator.

## Colour thresholds

| Spend | Colour |
|-------|--------|
| 0–50% | 🟢 Green |
| 51–80% | 🟠 Orange |
| 81–100% | 🔴 Red |

## How it works

The plugin runs JavaScript inside your existing claude.ai browser tab to call the Claude API and read your organisation's live spend data. No hardcoded credentials — your org ID is resolved dynamically at runtime.

- **Tab open** → live data fetched every hour
- **Tab closed** → last cached value shown (with `↻` indicator)
- **Cache** is stored locally at `~/.claude-usage-cache.json` (never leaves your machine)

## Requirements

- macOS
- [xbar](https://xbarapp.com) (free, direct download — not on the App Store)
- [Island browser](https://www.island.io) (Chromium-based) logged into claude.ai
- Python 3 (pre-installed on macOS)
- Island must have **Allow JavaScript from Apple Events** enabled:
  `View → Developer → Allow JavaScript from Apple Events`

> The plugin uses Island's AppleScript bridge to run JavaScript in your existing claude.ai tab. It does not store or transmit any credentials.

## Installation

1. Download and install [xbar](https://xbarapp.com).
2. Copy `claude-usage.1h.sh` into your xbar plugins folder:
```bash
cp claude-usage.1h.sh ~/Library/Application\ Support/xbar/plugins/
```
3. xbar picks it up automatically — you'll see **☁ X%** in your menu bar.

> **If xbar shows a "not executable" error**, run:
> ```bash
> chmod +x ~/Library/Application\ Support/xbar/plugins/claude-usage.1h.sh
> ```
> Then click **Refresh** in xbar.

## License

MIT
