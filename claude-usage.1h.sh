#!/usr/bin/env bash
# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Nicholas Soh</xbar.author>
# <xbar.author.github>nicholas-soh</xbar.author.github>
# <xbar.desc>Tracks Claude billing cycle progress in your menu bar. Click to open usage page.</xbar.desc>
# <xbar.dependencies>python3</xbar.dependencies>

python3 << 'EOF'
import datetime
import calendar

now = datetime.datetime.now()
year, month, day = now.year, now.month, now.day
days_in_month = calendar.monthrange(year, month)[1]
days_left = days_in_month - day
progress = int((day / days_in_month) * 100)
month_name = now.strftime("%B %Y")

filled = round(progress / 10)
empty = 10 - filled
bar = "█" * filled + "░" * empty

if progress <= 50:
    color = "#22c55e"  # green
elif progress <= 80:
    color = "#f97316"  # orange
else:
    color = "#ef4444"  # red

# Menu bar line
print(f"☁ {progress}% | color={color} size=13")
print("---")
print(f"Claude Usage | color=#ffffff size=14 href=https://claude.ai/settings/limits")
print(f"{month_name} | color=#9ca3af size=12")
print("---")
print(f"{bar}  {progress}% | color={color} font=Menlo size=12")
print(f"{days_left} days left in billing cycle | color=#9ca3af size=12")
print("---")
print("Open Usage Page | href=https://claude.ai/settings/limits color=#3b82f6")
print("Refresh | refresh=true color=#6b7280")
EOF
