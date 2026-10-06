#!/usr/bin/env bash
# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>v2.4</xbar.version>
# <xbar.author>Nicholas Soh</xbar.author>
# <xbar.author.github>nicholas-soh</xbar.author.github>
# <xbar.desc>Shows real Claude spend % in your menu bar via Island browser. Caches last value when no tab is open, and says why when it can't refresh.</xbar.desc>
# <xbar.dependencies>python3,osascript</xbar.dependencies>
#
# Requires a claude.ai tab open in Island, and Island's
# View → Developer → Allow JavaScript from Apple Events to be enabled.

USAGE_URL="https://claude.ai/new#settings/usage"
CACHE_FILE="$HOME/.claude-usage-cache.json"
UPDATE_CACHE="$HOME/.claude-usage-update.json"
REMOTE_URL="https://raw.githubusercontent.com/nicholas-soh/claude-usage-widget/main/claude-usage.1h.sh"
SELF="$0"

# One-click self-update, triggered from the dropdown (bash=$0 param1=--self-update).
# The download is validated before it replaces anything: a failed or truncated
# fetch leaves the installed copy untouched.
if [ "${1:-}" = "--self-update" ]; then
    notify() { osascript -e "display notification \"$1\" with title \"Claude Usage\"" >/dev/null 2>&1; }
    new=$(mktemp "$(dirname "$SELF")/.claude-usage-update.XXXXXX") || exit 1
    if curl -fsSL --max-time 20 "$REMOTE_URL" -o "$new" \
        && head -1 "$new" | grep -q '^#!/usr/bin/env bash' \
        && grep -q '^# <xbar.version>v' "$new" \
        && bash -n "$new" 2>/dev/null; then
        chmod +x "$new"
        mv "$new" "$SELF"
        rm -f "$UPDATE_CACHE"
        notify "Updated to $(sed -n 's/^# <xbar.version>\(.*\)<\/xbar.version>/\1/p' "$SELF" | head -1)"
    else
        rm -f "$new"
        notify "Update failed — check your connection and try again"
    fi
    exit 0
fi

TMPFILE=$(mktemp)
ERRFILE=$(mktemp)
trap 'rm -f "$TMPFILE" "$ERRFILE"' EXIT

# Only talk to Island if it's already running — avoids launching it
if ! pgrep -x "Island" > /dev/null 2>&1; then
    echo '{"error":"no_island"}' > "$TMPFILE"
else

# stderr is kept, not discarded: an osascript failure here is usually
# "Allow JavaScript from Apple Events" being switched off, and that is
# worth telling the user rather than silently falling back to cache.
osascript 2>"$ERRFILE" > "$TMPFILE" << 'APPLESCRIPT'
tell application "Island"
    set claudeTab to null
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains "claude.ai" then
                set claudeTab to t
                exit repeat
            end if
        end repeat
        if claudeTab is not null then exit repeat
    end repeat

    if claudeTab is null then
        return "{\"error\":\"no_tab\"}"
    end if

    execute claudeTab javascript "
        (function() {
            try {
                var xhr = new XMLHttpRequest();
                xhr.open('GET', '/api/account', false);
                xhr.setRequestHeader('Accept', 'application/json');
                xhr.send(null);
                if (xhr.status !== 200) return JSON.stringify({error: 'account_' + xhr.status});

                var account = JSON.parse(xhr.responseText);
                var orgUuid = account.memberships &&
                              account.memberships[0] &&
                              account.memberships[0].organization.uuid;
                if (!orgUuid) return JSON.stringify({error: 'no_org'});

                var xhr2 = new XMLHttpRequest();
                xhr2.open('GET', '/api/organizations/' + orgUuid + '/usage', false);
                xhr2.setRequestHeader('Accept', 'application/json');
                xhr2.send(null);
                if (xhr2.status !== 200) return JSON.stringify({error: 'usage_' + xhr2.status});

                return xhr2.responseText;
            } catch(e) {
                return JSON.stringify({error: e.toString()});
            }
        })()
    "
end tell
APPLESCRIPT

fi  # end Island running check

# Quoted heredoc: the Python below is opaque to bash, so a stray '$' in a
# format string can't be eaten before Python sees it. Values come in via env.
USAGE_URL="$USAGE_URL" CACHE_FILE="$CACHE_FILE" UPDATE_CACHE="$UPDATE_CACHE" \
REMOTE_URL="$REMOTE_URL" SELF="$SELF" \
TMPFILE="$TMPFILE" ERRFILE="$ERRFILE" python3 << 'PYEOF'
import datetime, json, os, re, sys, tempfile, time, urllib.request

USAGE_URL  = os.environ["USAGE_URL"]
CACHE_FILE = os.environ["CACHE_FILE"]
TMPFILE    = os.environ["TMPFILE"]
ERRFILE    = os.environ["ERRFILE"]
UPDATE_CACHE = os.environ["UPDATE_CACHE"]
REMOTE_URL   = os.environ["REMOTE_URL"]
SELF         = os.environ["SELF"]
UPDATE_CHECK_EVERY = 24 * 3600

BAR_LEN = 10

def color_for(pct):
    if pct <= 50: return "#22c55e"
    if pct <= 80: return "#f97316"
    return "#ef4444"

def bar_for(pct):
    # Clamped: utilization can in principle exceed 100, and an unclamped
    # bar silently grows past BAR_LEN instead of erroring.
    filled = int(round(pct / 100 * BAR_LEN))
    filled = max(0, min(BAR_LEN, filled))
    return "█" * filled + "░" * (BAR_LEN - filled)

def money(amount):
    return f"${amount:,.2f}"

def safe(text, limit=120):
    """Neutralise text before it reaches an xbar menu line.

    xbar splits a line on '|' and treats what follows as parameters — including
    bash=/shell=, which it will execute on click. Anything sourced from the API
    or from a JS exception must therefore be stripped of '|' and newlines, and
    bounded, before being interpolated into output.
    """
    text = str(text).replace("|", "/").replace("\n", " ").replace("\r", " ")
    text = " ".join(text.split())
    return text[:limit] + "…" if len(text) > limit else text

def describe(code):
    """Turn an internal error code into something actionable in the dropdown."""
    known = {
        "no_island":     "Island isn't running",
        "no_tab":        "No claude.ai tab open in Island",
        "no_org":        "No organization found on this account",
        "no_result":     "Island returned nothing",
        "bad_response":  "claude.ai returned an unreadable response",
        "applescript":   "Island blocked the query — enable View → Developer → Allow JavaScript from Apple Events",
    }
    if code in known:
        return known[code]
    for prefix, what in (("account_", "account"), ("usage_", "usage")):
        if code.startswith(prefix):
            status = code[len(prefix):]
            if status in ("401", "403"):
                return f"Signed out of claude.ai ({status}) — sign in to refresh"
            return f"claude.ai {what} API returned {safe(status, 24)}"
    return safe(code)

VERSION_RE = re.compile(r"^# <xbar\.version>v?([\d.]+)</xbar\.version>", re.M)

def parse_version(text):
    m = VERSION_RE.search(text)
    return tuple(int(x) for x in m.group(1).split(".") if x) if m else None

def local_version():
    try:
        with open(SELF) as f:
            return parse_version(f.read(2048))
    except Exception:
        return None

def available_update():
    """Return the newer remote version as a string, or None.

    Checks GitHub at most once a day and fails silent: an offline Mac or a
    GitHub hiccup must never break or slow the menu bar. Nothing is installed
    here — the user opts in by clicking the dropdown item.
    """
    local = local_version()
    if not local:
        return None

    cache = {}
    try:
        with open(UPDATE_CACHE) as f:
            cache = json.load(f)
    except Exception:
        pass

    latest = cache.get("latest")
    if time.time() - cache.get("checked", 0) > UPDATE_CHECK_EVERY:
        try:
            with urllib.request.urlopen(REMOTE_URL, timeout=4) as r:
                remote = parse_version(r.read(2048).decode("utf-8", "replace"))
            latest = ".".join(map(str, remote)) if remote else None
            with open(UPDATE_CACHE, "w") as f:
                json.dump({"checked": time.time(), "latest": latest}, f)
        except Exception:
            pass  # keep the last known value; retry on the next run

    try:
        latest_t = tuple(int(x) for x in latest.split(".")) if latest else None
    except Exception:
        latest_t = None
    if latest_t and latest_t > local:
        return latest
    return None

def print_update_item():
    latest = available_update()
    local = local_version()
    print("---")
    if latest:
        print(f"⬆ Update available: v{latest} — click to install | "
              f'bash="{SELF}" param1=--self-update terminal=false refresh=true color=#3b82f6')
    if local:
        print(f"Claude Usage Widget v{'.'.join(map(str, local))} | color=#6b7280 size=11")

def render(pct, used, limit, currency, cached=False, as_of=None, reason=None, notes=()):
    # Thresholds and bar both read the displayed value, so 50.4% can't
    # render green under a "<= 50" rule.
    c     = color_for(pct)
    bar   = bar_for(pct)
    month = (as_of or datetime.date.today()).strftime("%B %Y")
    label = f"☁ {pct}%" + (" ↻" if cached else "")
    print(f"{label} | color={c} size=13")
    print("---")
    print(f"Claude Usage — {month} | color=#ffffff size=14 href={USAGE_URL}")
    if cached:
        stamp = as_of.strftime("%-d %b %H:%M") if as_of else "unknown time"
        why   = reason or "open claude.ai in Island to refresh"
        print(f"Cached from {stamp} · {safe(why)} | color=#6b7280 size=11")
    print("---")
    print(f"{bar}  {pct}% | color={c} font=Menlo size=12")
    if used is not None and limit is not None:
        print(f"{money(used)} of {money(limit)} {safe(currency, 8)} used | color=#9ca3af size=11")
    for note in notes:
        print(f"{note} | color=#f97316 size=11")
    print("---")
    print(f"Open Usage Page | href={USAGE_URL} color=#3b82f6")
    print("Refresh | refresh=true color=#6b7280")
    print_update_item()

def load_cache():
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except Exception:
        return None

def save_cache(data):
    # Write-then-rename so a crash mid-write can't leave a truncated cache.
    tmp = None
    try:
        d = os.path.dirname(CACHE_FILE) or "."
        fd, tmp = tempfile.mkstemp(dir=d, prefix=".claude-usage-", suffix=".tmp")
        with os.fdopen(fd, "w") as f:
            json.dump(data, f)
        os.replace(tmp, CACHE_FILE)
    except Exception:
        if tmp:
            try: os.unlink(tmp)
            except Exception: pass

def show_unavailable(note, label="☁ —"):
    print(f"{label} | color=#6b7280 size=13")
    print("---")
    print(f"{safe(note)} | color=#9ca3af size=12")
    print("---")
    print(f"Open Usage Page | href={USAGE_URL} color=#3b82f6")
    print("Refresh | refresh=true color=#6b7280")
    print_update_item()

def show_fallback(code):
    reason = describe(code)
    cached = load_cache()
    if not cached:
        show_unavailable(reason)
        return

    ts    = cached.get("ts")
    as_of = datetime.datetime.fromtimestamp(ts) if ts else None

    # A reading from a previous billing month says nothing about this month's
    # spend — the counter resets on the 1st. Never replay it as if it were current.
    today = datetime.date.today()
    if as_of is None or (as_of.year, as_of.month) != (today.year, today.month):
        when = as_of.strftime("%B %Y") if as_of else "a previous month"
        show_unavailable(f"Last reading was {when} — {reason}")
        return

    render(cached["pct"], cached["used"], cached["limit"], cached["currency"],
           cached=True, as_of=as_of, reason=reason)

def die(code):
    show_fallback(code)
    sys.exit(0)

# --- read whatever the AppleScript stage produced -------------------------
raw = ""
try:
    with open(TMPFILE) as f:
        raw = f.read().strip()
except Exception:
    pass

if not raw or raw == "missing value":
    stderr = ""
    try:
        with open(ERRFILE) as f:
            stderr = f.read().strip()
    except Exception:
        pass
    die("applescript" if stderr or raw == "missing value" else "no_result")

try:
    data = json.loads(raw)
except Exception:
    die("bad_response")

if not isinstance(data, dict):
    die("bad_response")

if "error" in data:
    die(str(data["error"]))

# --- interpret the usage payload ------------------------------------------
extra = data.get("extra_usage") or {}
spend = data.get("spend") or {}

# The API states its own scale rather than implying cents.
places = extra.get("decimal_places")
if places is None:
    places = (spend.get("used") or {}).get("exponent")
if not isinstance(places, int):
    places = 2
scale = 10 ** places

enabled = extra.get("is_enabled")
if enabled is None:
    enabled = spend.get("enabled")
if enabled is False:
    why = extra.get("disabled_reason") or spend.get("disabled_reason")
    if not why:
        why = ("You turned extra usage off" if extra.get("user_disabled")
               else "Extra usage is disabled for this organization")
    show_unavailable(why, label="☁ off")
    sys.exit(0)

utilization = extra.get("utilization")
if utilization is None:
    die("bad_response")

used     = extra.get("used_credits")
limit    = extra.get("monthly_limit")
currency = extra.get("currency", "USD")

pct   = round(utilization, 1)
used  = used / scale if used is not None else None
limit = limit / scale if limit is not None else None

notes = []
if extra.get("spend_limit_reached") or spend.get("severity") == "critical":
    notes.append("⚠ Monthly spend limit reached")

save_cache({"pct": pct, "used": used, "limit": limit, "currency": currency,
            "ts": time.time()})
render(pct, used, limit, currency, cached=False, notes=notes)
PYEOF
