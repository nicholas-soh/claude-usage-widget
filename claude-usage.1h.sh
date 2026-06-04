#!/usr/bin/env bash
# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>v2.1</xbar.version>
# <xbar.author>Nicholas Soh</xbar.author>
# <xbar.author.github>nicholas-soh</xbar.author.github>
# <xbar.desc>Shows real Claude spend % in your menu bar via Island browser. Caches last value when no tab is open.</xbar.desc>
# <xbar.dependencies>python3,osascript</xbar.dependencies>

USAGE_URL="https://claude.ai/new#settings/usage"
CACHE_FILE="$HOME/.claude-usage-cache.json"
TMPFILE=$(mktemp)

osascript 2>/dev/null << 'APPLESCRIPT' > "$TMPFILE"
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

python3 << EOF
import json, sys, datetime, os

USAGE_URL  = "$USAGE_URL"
CACHE_FILE = "$CACHE_FILE"
TMPFILE    = "$TMPFILE"

def color_for(pct):
    if pct <= 50: return "#22c55e"
    if pct <= 80: return "#f97316"
    return "#ef4444"

def render(pct, used, limit, currency, cached=False):
    pct_i = round(pct)
    c     = color_for(pct_i)
    bar   = "█" * round(pct_i / 10) + "░" * (10 - round(pct_i / 10))
    month = datetime.date.today().strftime("%B %Y")
    label = f"☁ {pct}%" + (" ↻" if cached else "")
    print(f"{label} | color={c} size=13")
    print("---")
    print(f"Claude Usage — {month} | color=#ffffff size=14 href={USAGE_URL}")
    if cached:
        print("Cached — open claude.ai in Island to refresh | color=#6b7280 size=11")
    print("---")
    print(f"{bar}  {pct}% | color={c} font=Menlo size=12")
    if used is not None and limit is not None:
        print(f"\${used:,.2f} of \${limit:,.2f} {currency} used | color=#9ca3af size=11")
    print("---")
    print(f"Open Usage Page | href={USAGE_URL} color=#3b82f6")
    print("Refresh | refresh=true color=#6b7280")

def load_cache():
    try:
        return json.load(open(CACHE_FILE))
    except:
        return None

def save_cache(data):
    try:
        json.dump(data, open(CACHE_FILE, 'w'))
    except:
        pass

def show_fallback():
    cached = load_cache()
    if cached:
        render(cached["pct"], cached["used"], cached["limit"], cached["currency"], cached=True)
    else:
        print("☁ — | color=#6b7280 size=13")
        print("---")
        print("Open claude.ai in Island to enable | color=#9ca3af size=12")
        print("---")
        print(f"Open Usage Page | href={USAGE_URL} color=#3b82f6")
        print("Refresh | refresh=true color=#6b7280")

# Read live result
try:
    raw = open(TMPFILE).read().strip()
except:
    show_fallback(); sys.exit(0)

if not raw:
    show_fallback(); sys.exit(0)

try:
    data = json.loads(raw)
except:
    show_fallback(); sys.exit(0)

if "error" in data:
    show_fallback(); sys.exit(0)

extra = data.get("extra_usage", {})
utilization = extra.get("utilization")
used        = extra.get("used_credits")
limit       = extra.get("monthly_limit")
currency    = extra.get("currency", "USD")

if utilization is None:
    show_fallback(); sys.exit(0)

pct   = round(utilization, 1)
used  = used / 100 if used is not None else None
limit = limit / 100 if limit is not None else None
save_cache({"pct": pct, "used": used, "limit": limit, "currency": currency})
render(pct, used, limit, currency, cached=False)
EOF

rm -f "$TMPFILE"
