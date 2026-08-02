#!/usr/bin/env bash
# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>v2.2</xbar.version>
# <xbar.author>Nicholas Soh</xbar.author>
# <xbar.author.github>nicholas-soh</xbar.author.github>
# <xbar.desc>Shows real Claude spend % in your menu bar via Island browser. Caches last value when no tab is open, and says why when it can't refresh.</xbar.desc>
# <xbar.dependencies>python3,osascript</xbar.dependencies>
#
# Requires a claude.ai tab open in Island, and Island's
# View → Developer → Allow JavaScript from Apple Events to be enabled.

USAGE_URL="https://claude.ai/new#settings/usage"
CACHE_FILE="$HOME/.claude-usage-cache.json"
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
USAGE_URL="$USAGE_URL" CACHE_FILE="$CACHE_FILE" \
TMPFILE="$TMPFILE" ERRFILE="$ERRFILE" python3 << 'PYEOF'
import datetime, json, os, sys, tempfile, time

USAGE_URL  = os.environ["USAGE_URL"]
CACHE_FILE = os.environ["CACHE_FILE"]
TMPFILE    = os.environ["TMPFILE"]
ERRFILE    = os.environ["ERRFILE"]

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
