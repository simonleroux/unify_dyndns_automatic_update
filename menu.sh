#!/bin/sh
# Unifi_scripts Main Menu

REPO_URL="https://raw.githubusercontent.com/simonleroux/unify_scripts/refs/heads/main"
TMP_DIR="/tmp/stetnet_scripts"
mkdir -p "$TMP_DIR"

show_menu() {
    echo "====================================="
    echo "       STETNET Unifi Scripts         "
    echo "====================================="
    echo "1) Install Automatic Cloudflare/NextDNS Update"
    echo "2) Install WireGuard Failover"
    echo "3) Uninstall All STETNET scripts"
    echo "4) Exit"
    echo "====================================="
}

while true; do
    show_menu
    echo -n "Select an option [1-4]: "
    read choice < /dev/tty
    case $choice in
        1)
            # Interactive installation for Cloudflare/NextDNS
            echo ""
            echo "📝 Cloudflare/NextDNS Configuration"
            echo "===================================="
            echo ""
            echo "⏱️  INTERVAL (minutes): How often to check IP (e.g., 5)"
            echo -n "    Enter interval [default: 5]: "
            read INTERVAL < /dev/tty
            INTERVAL=${INTERVAL:-5}
            echo ""
            echo "🌐 HOSTNAME: Your fully qualified domain name (e.g., home.example.com)"
            echo -n "    Enter hostname: "
            read HOSTNAME < /dev/tty
            echo ""
            echo "🔵 NEXTDNS URL: Your update link (optional, e.g., https://link-XXXXX.nextdns.io/YYYY)"
            echo -n "    Enter NextDNS URL (leave blank to skip): "
            read NEXTDNS_URL < /dev/tty
            echo ""
            echo "🟠 CLOUDFLARE API TOKEN: Get from https://dash.cloudflare.com/profile/api-tokens (DNS:Edit)"
            echo -n "    Enter API Token: "
            read CF_TOKEN < /dev/tty
            echo ""
            echo "🟠 ZONE ID: From Cloudflare Domain Overview (right sidebar)"
            echo -n "    Enter Zone ID: "
            read CF_ZONE < /dev/tty
            echo ""
            echo "🟠 RECORD ID: From Cloudflare DNS Records (specific A record for hostname)"
            echo -n "    Enter Record ID: "
            read CF_REC < /dev/tty
            echo ""
            echo "🚀 Installing with your configuration..."
            echo ""
            curl -fsSL --max-time 60 "$REPO_URL/install_cloudflare.sh" -o "$TMP_DIR/install_cloudflare.sh" && sh "$TMP_DIR/install_cloudflare.sh" "$INTERVAL" "$HOSTNAME" "$NEXTDNS_URL" "$CF_TOKEN" "$CF_ZONE" "$CF_REC"
            echo ""
            echo ""
            echo -n "Press Enter to return to menu..."
            read dummy < /dev/tty
            ;;
        2)
            curl -fsSL --max-time 60 "$REPO_URL/install_wg.sh" -o "$TMP_DIR/install_wg.sh" && sh "$TMP_DIR/install_wg.sh"
            echo ""
            echo ""
            echo -n "Press Enter to return to menu..."
            read dummy < /dev/tty
            ;;
        3)
            curl -fsSL --max-time 60 "$REPO_URL/uninstall_all.sh" -o "$TMP_DIR/uninstall_all.sh" && sh "$TMP_DIR/uninstall_all.sh"
            echo ""
            echo ""
            echo -n "Press Enter to return to menu..."
            read dummy < /dev/tty
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
