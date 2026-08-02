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

## Colour thresholds

| Spend | Colour |
|-------|--------|
| 0–50% | 🟢 Green |
| 51–80% | 🟠 Orange |
| 81–100% | 🔴 Red |

## How it works

The plugin runs JavaScript inside your existing claude.ai browser tab to call the Claude API and read your organisation's live spend data. No hardcoded credentials — your org ID is resolved dynamically at runtime.

- **Tab open** → live data fetched every hour
- **Tab closed** → last cached value shown, with a `↻` marker, a timestamp, and the reason it couldn't refresh
- **Cache** is stored locally at `~/.claude-usage-cache.json`, mode `600` (never leaves your machine)

### 💡 Pin your claude.ai tab

The plugin needs a claude.ai tab to exist. **Right-click the tab → Pin.** Pinned tabs survive browser restarts, shrink to a favicon, and can't be closed with ⌘W by accident. Without this, the widget goes dormant the moment you tidy up your tabs.

### When it can't refresh

Rather than silently showing an old number, the widget says what's wrong:

| Menu bar | Dropdown says | Fix |
|----------|---------------|-----|
| `☁ —` | No claude.ai tab open in Island | Open (and pin) a claude.ai tab |
| `☁ —` | Island isn't running | Launch Island |
| `☁ —` | Signed out of claude.ai (401) | Sign back in |
| `☁ —` | Island blocked the query — enable Develop ▸ Allow JavaScript from Apple Events | See install step 2 |
| `☁ off` | Extra usage is disabled | Nothing to track |
| `☁ 30% ↻` | Cached from 3 Aug 09:15 · *reason* | Value is stale but still from this month |

**A cached reading from a previous month is never shown.** Spend resets on the 1st, so a June figure tells you nothing about July — the widget reports `☁ —` and says when the last reading was, rather than passing off stale data as current.

## Requirements

- macOS
- [xbar](https://xbarapp.com) (free, direct download — not on the App Store)
- [Island browser](https://www.island.io) (Chromium-based) logged into claude.ai
- Python 3 (pre-installed on macOS)
- Island must have **Allow JavaScript from Apple Events** enabled:
  `View → Developer → Allow JavaScript from Apple Events`

## Security

- **No credentials are stored, read, or transmitted.** The plugin never touches your cookie store, Keychain, or session token. It borrows an already-authenticated page through Island's AppleScript bridge and lets the browser attach cookies itself.
- **Nothing leaves your machine.** The only network calls are the two same-origin API requests the browser makes; the cache is a local file.
- **Island is never launched.** If it isn't already running, the plugin skips the query entirely.
- **All API-sourced text is sanitised before display.** xbar treats `|` as the separator introducing menu parameters — including `bash=`, which it executes on click — so any string originating from the API or a JS exception is stripped of `|` and newlines and length-bounded before it reaches a menu line.

## Installation

1. Download and install [xbar](https://xbarapp.com).
2. In Island, enable JavaScript from Apple Events:
   `View → Developer → Allow JavaScript from Apple Events`
3. Run the install script — it downloads the plugin, sets the executable bit, and puts it in the right place:
```bash
curl -fsSL https://raw.githubusercontent.com/nicholas-soh/claude-usage-widget/main/install.sh | bash
```
4. Open claude.ai in Island and **pin the tab**.
5. xbar picks it up automatically — you'll see **☁ X%** in your menu bar.

## License

MIT
