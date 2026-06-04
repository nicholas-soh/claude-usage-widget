# Claude Usage Widget for xbar

A macOS menu bar plugin that shows your Claude billing cycle progress and links directly to your usage page.

## What it looks like

```
☁ 60%   ← in your menu bar (colour changes by threshold)

Clicking opens a dropdown:
─────────────────────
Claude Usage
June 2026
─────────────────────
██████░░░░  60%
18 days left in billing cycle
─────────────────────
Open Usage Page
Refresh
```

## Colour thresholds

| Usage | Colour |
|-------|--------|
| 0–50% | 🟢 Green |
| 51–80% | 🟠 Orange |
| 81–100% | 🔴 Red |

## Installation

1. Download and install [xbar](https://xbarapp.com) (free, direct download — not on the App Store).
2. Open xbar — it will prompt you to choose a plugins folder (default is fine).
3. Copy `claude-usage.1h.sh` into your xbar plugins folder (`~/Library/Application Support/xbar/plugins/`).
4. xbar picks it up automatically — you'll see **☁ X%** appear in your menu bar.

Or copy it in one command:
```bash
cp claude-usage.1h.sh ~/Library/Application\ Support/xbar/plugins/
```

## Usage

- **Menu bar** shows the percentage of the billing cycle elapsed, refreshed every hour, colour-coded by threshold.
- **Click** the menu bar item to see the progress bar and dropdown.
- **"Open Usage Page"** jumps to [claude.ai/settings/limits](https://claude.ai/settings/limits) for your actual usage %.
- The progress bar is time-based (days elapsed), not usage-based — Claude doesn't expose live usage data via a public API.

## Requirements

- macOS with [xbar](https://xbarapp.com) installed
- Python 3 (pre-installed on macOS)

## License

MIT
