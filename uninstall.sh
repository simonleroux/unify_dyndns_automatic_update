#!/bin/sh
# automatic_update Uninstaller

SERVICE_DIR="/data/STETNET/automatic_update"
SERVICE_NAME="automatic_update.service"
TIMER_NAME="automatic_update.timer"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TIMER_PATH="/etc/systemd/system/$TIMER_NAME"

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "🔧 Stopping and disabling systemd units..."
systemctl stop "$TIMER_NAME" 2>/dev/null
systemctl disable "$TIMER_NAME" 2>/dev/null
systemctl stop "$SERVICE_NAME" 2>/dev/null
systemctl disable "$SERVICE_NAME" 2>/dev/null

echo "🗑️ Removing systemd files..."
rm -f "$TIMER_PATH"
rm -f "$SERVICE_PATH"

# Refresh systemd to remove the "not-found" entries
systemctl daemon-reload
systemctl reset-failed

echo "📂 Removing script directory..."
if [ -d "$SERVICE_DIR" ]; then
    rm -rf "$SERVICE_DIR"
fi

echo "${GREEN}✅ Uninstallation complete.${NC}"