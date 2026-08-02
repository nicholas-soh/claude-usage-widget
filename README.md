# Claude Usage Widget for xbar

A macOS menu bar plugin that shows how much of your **extra usage credit** budget you've spent this month, read live from your own claude.ai session.

```
☁ 12%   ← in your menu bar
```

## What this actually measures

This tracks **extra usage credits** — the spend that kicks in *after* you exhaust your plan's included limits. In Claude's own words:

> Usage credits cover you when you hit your plan limits.

So `☁ 12%` means *"I've used 12% of my monthly extra-usage budget"*, **not** "I've used 12% of my Claude plan".

Two consequences worth knowing up front:

- If you never exceed your plan limits, this sits near **0%** all month. That's the widget working, not failing.
- It does **not** show your 5-hour or weekly rate limits — the ones that actually pause your session. Those live elsewhere in the same API response but are usually `null`, so the widget doesn't read them.

If what you want is "how close am I to being rate-limited", this is the wrong tool.

## The dropdown

```
☁ 12%
─────────────────────────────
Claude Usage — August 2026
─────────────────────────────
█░░░░░░░░░  12%
$180.00 of $1,500.00 USD used
─────────────────────────────
Open Usage Page
Refresh
```

| Spend | Colour |
|-------|--------|
| 0–50% | 🟢 Green |
| 51–80% | 🟠 Orange |
| Over 80% | 🔴 Red |

## How it works

The plugin runs a JavaScript `XMLHttpRequest` inside your existing claude.ai tab, so the browser attaches your session cookies itself. Nothing is stored, and your org ID is resolved at runtime rather than hardcoded.

- **Tab open** → live data, refreshed hourly
- **Tab closed** → last cached value, with a `↻` marker, a timestamp, and the reason it couldn't refresh
- **Cache** lives at `~/.claude-usage-cache.json`, mode `600`, and never leaves your machine

### 💡 Pin your claude.ai tab

The plugin needs a claude.ai tab to exist. **Right-click the tab → Pin.** Pinned tabs survive browser restarts, shrink to a favicon, and can't be closed with ⌘W by accident. Without this the widget goes dormant the moment you tidy up your tabs — which is the single most common way it stops working.

### When it can't refresh

Rather than quietly showing an old number, the widget says what's wrong:

| Menu bar | Dropdown says | Fix |
|----------|---------------|-----|
| `☁ —` | No claude.ai tab open in Island | Open — and pin — a claude.ai tab |
| `☁ —` | Island isn't running | Launch Island |
| `☁ —` | Signed out of claude.ai (401) | Sign back in |
| `☁ —` | Island blocked the query — enable View → Developer → Allow JavaScript from Apple Events | See install step 2 |
| `☁ —` | Last reading was July 2026 — *reason* | Stale across a month boundary; see below |
| `☁ off` | Extra usage is disabled | Nothing to track |
| `☁ 12% ↻` | Cached from 3 Aug 09:15 · *reason* | Stale, but still from this month |

**A cached reading from a previous month is never shown.** Credits reset on the 1st, so a July figure says nothing about August. The widget reports `☁ —` with the date of the last good reading instead of passing stale data off as current.

## Requirements

- macOS
- [xbar](https://xbarapp.com) — free, direct download, not on the App Store
- [Island browser](https://www.island.io), signed in to claude.ai
- Python 3.6+ — `/usr/bin/python3` on macOS comes from the Xcode Command Line Tools. If you've ever run `git` or `xcode-select --install` you already have it; otherwise macOS will prompt on first use.
- **Allow JavaScript from Apple Events** enabled in Island: `View → Developer → Allow JavaScript from Apple Events`

## Installation

1. Install [xbar](https://xbarapp.com).
2. In Island, enable `View → Developer → Allow JavaScript from Apple Events`.
3. Install the plugin:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/nicholas-soh/claude-usage-widget/main/install.sh | bash
   ```
4. Open claude.ai in Island and **pin the tab**.
5. xbar picks it up automatically — you'll see **☁ X%** in your menu bar.

## Customising

**Refresh interval** is encoded in the filename. Rename the plugin in `~/Library/Application Support/xbar/plugins/` and xbar picks up the new schedule:

| Filename | Refreshes |
|---|---|
| `claude-usage.15m.sh` | every 15 minutes |
| `claude-usage.1h.sh` | hourly (default) |
| `claude-usage.6h.sh` | every 6 hours |

**Using a different Chromium browser** — the plugin targets Island, but any Chromium browser with an AppleScript bridge works. Replace `tell application "Island"` with e.g. `tell application "Google Chrome"`, and change the `pgrep -x "Island"` guard to match the process name. The same *Allow JavaScript from Apple Events* setting must be enabled there too.

**Uninstall** — delete the plugin and its cache:
```bash
rm ~/Library/Application\ Support/xbar/plugins/claude-usage.*.sh
rm ~/.claude-usage-cache.json
```

## Security

- **No credentials are stored, read, or transmitted.** The plugin never touches your cookie store, Keychain, or session token. It borrows an already-authenticated page and lets the browser handle auth.
- **Nothing leaves your machine.** The only network calls are the two same-origin requests the browser makes; the cache is a local file.
- **Island is never launched.** If it isn't already running, the plugin skips the query entirely.
- **All API-sourced text is sanitised before display.** xbar treats `|` as the separator introducing menu parameters — including `bash=`, which it executes on click — so any string coming from the API or a JS exception is stripped of `|` and newlines and length-bounded before it reaches a menu line.

## Limitations

- **Island-specific** as shipped (see *Customising* to retarget it).
- **Needs a live tab.** There's no headless path; the plugin has no credentials of its own by design.
- **Depends on an undocumented endpoint.** `/api/organizations/{uuid}/usage` is what claude.ai's own settings page uses. It can change without notice — if it does, the widget shows an error rather than a wrong number.

## License

MIT
