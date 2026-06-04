#!/usr/bin/env bash
set -e

PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"
SCRIPT_NAME="claude-usage.1h.sh"
REPO_URL="https://raw.githubusercontent.com/nicholas-soh/claude-usage-widget/main/$SCRIPT_NAME"

echo "Installing Claude Usage Widget for xbar..."

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Error: xbar plugins folder not found at: $PLUGIN_DIR"
    echo "Please install xbar first: https://xbarapp.com"
    exit 1
fi

curl -fsSL "$REPO_URL" -o "$PLUGIN_DIR/$SCRIPT_NAME"
chmod +x "$PLUGIN_DIR/$SCRIPT_NAME"

echo "Done. Refresh xbar to see the widget."
