#!/bin/sh
# Unifi Leroux Automatic update Installer with customizable interval

SERVICE_DIR="/data/STETNET/automatic_update"
SERVICE_NAME="automatic_update.service"
TIMER_NAME="automatic_update.timer"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TIMER_PATH="/etc/systemd/system/$TIMER_NAME"

INTERVAL_MIN="${1:-5}"
hostname="$2"
nextDNSUrlUpdate="$3"
cloudflareAPIToken="$4"
cloudflareZoneId="$5"
cloudflareRecordId="$6"

mkdir -p "$SERVICE_DIR"

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo "🔧 Writing Leroux Automatic update script..."
cat << EOF > "$SERVICE_DIR/automatic_update.sh"
#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================

hostname=$hostname
nextdnsUrl=$nextDNSUrlUpdate

# Cloudflare API Credentials
CF_API_TOKEN=$cloudflareAPIToken
CF_ZONE_ID=$cloudflareZoneId
CF_RECORD_ID=$cloudflareRecordId


# ==========================================
# CHECK IP RESOLUTION
# ==========================================
printf "Checking if we should change \$hostname IP resolution\n"

# Get current public WAN IP
currentIp=$(curl -s 'api.ipify.org' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

# Check existing record IP directly via Cloudflare's public resolver
resolvedIp=$(nslookup $hostname 1.1.1.1 | awk '/^Address: / { print $2 }')

printf "Current IP : \$currentIp\nResolved IP : \$resolvedIp\n"

# ==========================================
# UPDATE IF MISMATCHED
# ==========================================
if [ "$currentIp" != "$resolvedIp" ]; then
    printf "IP addresses do not match, initiating updates...\n"
    
    # 1. Update NextDNS
    printf "Updating NextDNS...\n"
    curl -s "$nextdnsUrl"
    printf "\n"

    # 2. Update Cloudflare DNS
    printf "Updating Cloudflare...\n"
    cfResponse=$(curl -s --request PATCH \
      --url "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
      --header "Authorization: Bearer $CF_API_TOKEN" \
      --header "Content-Type: application/json" \
      --data "{
        \"type\": \"A\",
        \"name\": \"$hostname\",
        \"content\": \"$currentIp\",
        \"proxied\": false
      }")

    # Check Cloudflare Response
    if echo "$cfResponse" | grep -q '"success":true'; then
        printf "Cloudflare updated successfully.\n"
    else
        printf "Error: Cloudflare update failed.\n"
        printf "API Response: $cfResponse\n"
    fi
else
    printf "IP addresses match, exiting\n"
fi

exit 0
EOF

chmod +x "$SERVICE_DIR/automatic_update.sh"

echo "🔧 Creating systemd service..."
cat << EOF > "$SERVICE_DIR/$SERVICE_NAME"

[Unit]
Description=STETNET: Apply automatic updater
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=$SERVICE_DIR/automatic_update.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

echo "⏲️ Creating systemd timer with $INTERVAL_MIN min interval..."
cat << EOF > "$SERVICE_DIR/$TIMER_NAME"
[Unit]
Description=Run automatic update every $INTERVAL_MIN minutes

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

echo "\n🔍 ${YELLOW}STETNET Overall Automatic updater Status${NC}"
echo "---------------------------------------"

echo "\n📦 Service Status:"
if systemctl is-active --quiet automatic_update.service; then
  echo "${GREEN}✅ automatic_update.service is active${NC}"
else
  echo "${YELLOW}ℹ️ automatic_update.service is currently inactive (normal)."
  echo "   It will be triggered automatically by automatic_update.timer every 1 minutes.${NC}"
fi

echo "\n⏱️ Timer Status:"
if systemctl is-active --quiet automatic_update.timer; then
  echo "${GREEN}✅ automatic_update.timer is active${NC}"
else
  echo "${RED}❌ automatic_update.timer is inactive${NC}"
fi

echo "\n🗓️ Next Timer Trigger:"
systemctl list-timers --all | grep automatic_update || echo "${YELLOW}⚠️ Timer not scheduled${NC}"

echo "\n📝 Last Service Run Log:"
journalctl -u automatic_update.service --no-pager -n 5
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
