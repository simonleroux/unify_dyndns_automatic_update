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
hostname="$hostname"
nextdnsUrl="$nextDNSUrlUpdate"

# Cloudflare API Credentials
CF_API_TOKEN="$cloudflareAPIToken"
CF_ZONE_ID="$cloudflareZoneId"
CF_RECORD_ID="$cloudflareRecordId"
EOF

cat << 'EOF' >> "$SERVICE_DIR/automatic_update.sh"

# ==========================================
# CHECK IP RESOLUTION
# ==========================================
printf "Checking if we should change $hostname IP resolution\n"

# Get current public WAN IP
currentIp=$(curl -s --max-time 10 'https://api.ipify.org' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

# Resolve all A records for the hostname via Cloudflare's public resolver
# (parses the lines after "Name:" so both BIND and busybox nslookup output work)
resolvedIps=$(nslookup "$hostname" 1.1.1.1 2>/dev/null | sed -n '/^Name/,$p' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')

printf "Current IP : $currentIp\nResolved IPs : $(echo $resolvedIps)\n"

# Skip this run if either lookup came back empty
if [ -z "$currentIp" ] || [ -z "$resolvedIps" ]; then
    printf "Could not determine current IP or resolve $hostname, skipping this run.\n"
    exit 1
fi

# ==========================================
# UPDATE IF MISMATCHED
# ==========================================
if ! echo "$resolvedIps" | grep -qx "$currentIp"; then
    printf "IP addresses do not match, initiating updates...\n"
    
    # 1. Update NextDNS (skipped if no NextDNS URL was given)
    if [ -n "$nextdnsUrl" ]; then
        printf "Updating NextDNS...\n"
        curl -s --max-time 10 "$nextdnsUrl"
        printf "\n"
    fi

    # 2. Update Cloudflare DNS
    printf "Updating Cloudflare...\n"
    cfResponse=$(curl -s --max-time 10 --request PATCH \
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
cat << EOF > "$SERVICE_DIR/status.sh"
#!/bin/sh

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo ""
echo "🔍 \${YELLOW}STETNET Overall Automatic updater Status\${NC}"
echo "---------------------------------------"

echo ""
echo "📦 Service Status:"
if systemctl is-active --quiet automatic_update.service; then
  echo "\${GREEN}✅ automatic_update.service is active\${NC}"
else
  echo "\${YELLOW}ℹ️ automatic_update.service is currently inactive (normal)."
  echo "   It will be triggered automatically by automatic_update.timer every $INTERVAL_MIN minutes.\${NC}"
fi

echo ""
echo "⏱️ Timer Status:"
if systemctl is-active --quiet automatic_update.timer; then
  echo "\${GREEN}✅ automatic_update.timer is active\${NC}"
else
  echo "\${RED}❌ automatic_update.timer is inactive\${NC}"
fi

echo ""
echo "🗓️ Next Timer Trigger:"
systemctl list-timers --all | grep automatic_update || echo "\${YELLOW}⚠️ Timer not scheduled\${NC}"

echo ""
echo "📝 Last Service Run Log:"
# Get the ID of the most recent execution
INVOCATION_ID=\$(systemctl show -p InvocationID --value automatic_update.service)

if [ -n "\$INVOCATION_ID" ]; then
    # Show only the logs for that specific execution ID
    journalctl _SYSTEMD_INVOCATION_ID=\$INVOCATION_ID --no-pager
else
    echo "\${YELLOW}No logs found for the last execution.\${NC}"
fi
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
