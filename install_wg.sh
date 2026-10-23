#!/bin/sh
# WireGuard Failover Installer
# A systemd service/timer package to monitor and re-resolve WireGuard peer endpoints.

SERVICE_DIR="/data/STETNET/wg_failover"
SERVICE_NAME="wg_failover.service"
TIMER_NAME="wg_failover.timer"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TIMER_PATH="/etc/systemd/system/$TIMER_NAME"

echo "🔧 WireGuard Failover Installer"
echo "------------------------------"

read -p "Enter WireGuard Interface (e.g., wgclt2): " INTERFACE < /dev/tty
read -p "Enter Peer Public Key: " PUBLIC_KEY < /dev/tty
read -p "Enter Endpoint Domain (e.g., vpn.example.com): " ENDPOINT_DOMAIN < /dev/tty
read -p "Enter Endpoint Port: " ENDPOINT_PORT < /dev/tty
read -p "Enter Check Interval in Seconds (default 10): " INTERVAL_SEC < /dev/tty
INTERVAL_SEC=${INTERVAL_SEC:-10}

mkdir -p "$SERVICE_DIR"

echo "🔧 Writing WireGuard Failover script..."
cat << EOF > "$SERVICE_DIR/wireguard-dns-resolver.sh"
#!/bin/bash
# Dedicated WireGuard Dynamic Endpoint Resolver
# ==================== CONFIGURATION ====================
INTERFACE="$INTERFACE"
PUBLIC_KEY="$PUBLIC_KEY"
ENDPOINT_DOMAIN="$ENDPOINT_DOMAIN"
ENDPOINT_PORT="$ENDPOINT_PORT"
# =======================================================
export LC_ALL=C

# 1. Resolve the target domain name to get the expected IP
EXPECTED_IP=\$(nslookup "\$ENDPOINT_DOMAIN" 1.1.1.1 | awk '/^Address: / { print \$2 }' | head -n1)

# Safety check
if [ -z "\$EXPECTED_IP" ]; then
    echo "Error: DNS resolution for \$ENDPOINT_DOMAIN failed. Skipping check."
    exit 1
fi

# 2. Extract current remote IP
CURRENT_IP=\$(wg show "\$INTERFACE" endpoints 2>/dev/null | grep -F "\$PUBLIC_KEY" | awk '{print \$2}' | cut -d: -f1)

# 3. Compare IPs
if [ "\$CURRENT_IP" = "\$EXPECTED_IP" ]; then
    echo "Tunnel is healthy."
else
    echo "Tunnel is UNHEALTHY. DNS says \$EXPECTED_IP, WireGuard is pointing to \$CURRENT_IP."
    echo "Realigning endpoint to \$EXPECTED_IP:\$ENDPOINT_PORT..."
    wg set "\$INTERFACE" peer "\$PUBLIC_KEY" endpoint "\$EXPECTED_IP:\$ENDPOINT_PORT"
    ip link set "\$INTERFACE" down && sleep 1 && ip link set "\$INTERFACE" up
fi
EOF

chmod +x "$SERVICE_DIR/wireguard-dns-resolver.sh"

echo "🔧 Creating systemd service..."
cat << EOF > "$SERVICE_DIR/$SERVICE_NAME"
[Unit]
Description=STETNET: WireGuard Dynamic Endpoint Resolver
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=$SERVICE_DIR/wireguard-dns-resolver.sh

[Install]
WantedBy=multi-user.target
EOF

echo "⏲️ Creating systemd timer with $INTERVAL_SEC second interval..."
cat << EOF > "$SERVICE_DIR/$TIMER_NAME"
[Unit]
Description=Run WireGuard failover check every $INTERVAL_SEC seconds

[Timer]
OnBootSec=10
OnUnitActiveSec=$INTERVAL_SEC
Unit=$SERVICE_NAME

[Install]
WantedBy=timers.target
EOF

ln -sf "$SERVICE_DIR/$SERVICE_NAME" "$SERVICE_PATH"
ln -sf "$SERVICE_DIR/$TIMER_NAME" "$TIMER_PATH"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl enable "$TIMER_NAME"
systemctl start "$SERVICE_NAME"
systemctl start "$TIMER_NAME"

echo "✅ Installed WireGuard Failover check every $INTERVAL_SEC seconds."
