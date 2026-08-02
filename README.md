# Claude Usage Widget for xbar

A macOS menu bar plugin that shows how much of your organisation's **monthly Claude usage-credit budget** you've spent, read live from your own claude.ai session. Built for Claude Enterprise.

```
☁ 12%   ← in your menu bar
```

## What this measures

Your organisation's **monthly usage-credit budget**, and how much of it you've spent. `☁ 12%` means 12% of this month's credit allowance is gone.

This is built for **Claude Enterprise** accounts, where there are no 5-hour or weekly rate-limit windows. The credit budget is therefore the one ceiling you can actually run into, which makes it the number worth putting in a menu bar. The widget deliberately reads nothing else.

<details>
<summary>If you're not on Enterprise</summary>

On personal plans (Pro / Max) the same field exists but means something narrower — only the overage that begins once your plan's included usage is exhausted. Claude's own description of it is *"Usage credits cover you when you hit your plan limits."*

On those plans the widget will usually read **0%** all month, because the thing that constrains you first is the 5-hour or weekly rate-limit window — and this widget does not read those. It'll work, it just won't tell you what you want to know.

</details>

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
- A **Claude Enterprise** account with usage credits enabled (see [What this measures](#what-this-measures))
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
