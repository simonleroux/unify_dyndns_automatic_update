#!/bin/sh
# freeDNS Installer with customizable interval

SERVICE_DIR="/data/STETNET/freedns_update"
SERVICE_NAME="freedns_update.service"
TIMER_NAME="freedns_update.timer"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TIMER_PATH="/etc/systemd/system/$TIMER_NAME"

INTERVAL_MIN="${1:-5}"
hostname="$2"
directUrlUpdate="$3"

mkdir -p "$SERVICE_DIR"

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo "🔧 Writing FreeDNS script..."
cat << 'EOF' > "$SERVICE_DIR/custom_dyndns.sh"
#!/bin/bash

printf "Checking if we should change \$hostname IP resolution\n"

currentIp=$(curl 'https://api.ipify.org?format=json' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
resolvedIp=$(nslookup \$hostname ns2.afraid.org | awk '/^Address: / { print $2 }')

printf "Current IP : $currentIp\nResolved IP : $resolvedIp\n"

if [[ "$currentIp" != "$resolvedIp" ]]; then
    printf "IP addresses do not match, need to update value at freedns\n"
    curl \$directUrlUpdate
else
    printf "IP addresses matches, exiting\n"
fi

exit 0
EOF

chmod +x "$SERVICE_DIR/custom_dyndns.sh"

echo "🔧 Creating systemd service..."
cat << EOF > "$SERVICE_DIR/$SERVICE_NAME"

[Unit]
Description=STETNET: Apply FreeDNS updater
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=$SERVICE_DIR/custom_dyndns.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

echo "⏲️ Creating systemd timer with $INTERVAL_MIN min interval..."
cat << EOF > "$SERVICE_DIR/$TIMER_NAME"
[Unit]
Description=Run FreeDNS update every $INTERVAL_MIN minutes

[Timer]
OnBootSec=30
OnCalendar=*:0/${INTERVAL_MIN}
Unit=$SERVICE_NAME

[Install]
WantedBy=timers.target
EOF

echo "📄 Adding status.sh..."
cat << 'EOF' > "$SERVICE_DIR/status.sh"
#!/bin/sh

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "\n🔍 ${YELLOW}STETNET Overall FreeDNS Status${NC}"
echo "---------------------------------------"

echo "\n📦 Service Status:"
if systemctl is-active --quiet $SERVICE_NAME; then
  echo "${GREEN}✅ $SERVICE_NAME is active${NC}"
else
  echo "${YELLOW}ℹ️ $SERVICE_NAME is currently inactive (normal)."
  echo "   It will be triggered automatically by $TIMER_NAME every N minutes.${NC}"
fi

echo "\n⏱️ Timer Status:"
if systemctl is-active --quiet $TIMER_NAME; then
  echo "${GREEN}✅ $TIMER_NAME is active${NC}"
else
  echo "${RED}❌ $TIMER_NAME is inactive${NC}"
fi

echo "\n🗓️ Next Timer Trigger:"
systemctl list-timers --all | grep freedns_update || echo "${YELLOW}⚠️ Timer not scheduled${NC}"

echo "\n📝 Last Service Run Log:"
journalctl -u $SERVICE_NAME --no-pager -n 5
EOF

chmod +x "$SERVICE_DIR/status.sh"

ln -sf "$SERVICE_DIR/$SERVICE_NAME" "$SERVICE_PATH"
ln -sf "$SERVICE_DIR/$TIMER_NAME" "$TIMER_PATH"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl enable "$TIMER_NAME"
systemctl start "$SERVICE_NAME"
systemctl start "$TIMER_NAME"

echo ""
echo "${GREEN}✅ Installed and scheduled every $INTERVAL_MIN min.${NC}"
