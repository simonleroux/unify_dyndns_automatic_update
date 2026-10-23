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
    read -p "Select an option [1-4]: " choice < /dev/tty
    case $choice in
        1)
            # Interactive installation for Cloudflare/NextDNS
            echo ""
            echo "📝 Cloudflare/NextDNS Configuration"
            echo "===================================="
            echo ""
            echo "⏱️  INTERVAL (minutes): How often to check IP (e.g., 5)"
            read -p "    Enter interval [default: 5]: " INTERVAL < /dev/tty
            INTERVAL=${INTERVAL:-5}
            echo ""
            echo "🌐 HOSTNAME: Your fully qualified domain name (e.g., home.example.com)"
            read -p "    Enter hostname: " HOSTNAME < /dev/tty
            echo ""
            echo "🔵 NEXTDNS URL: Your update link (optional, e.g., https://link-XXXXX.nextdns.io/YYYY)"
            read -p "    Enter NextDNS URL (leave blank to skip): " NEXTDNS_URL < /dev/tty
            echo ""
            echo "🟠 CLOUDFLARE API TOKEN: Get from https://dash.cloudflare.com/profile/api-tokens (DNS:Edit)"
            read -p "    Enter API Token: " CF_TOKEN < /dev/tty
            echo ""
            echo "🟠 ZONE ID: From Cloudflare Domain Overview (right sidebar)"
            read -p "    Enter Zone ID: " CF_ZONE < /dev/tty
            echo ""
            echo "🟠 RECORD ID: From Cloudflare DNS Records (specific A record for hostname)"
            read -p "    Enter Record ID: " CF_REC < /dev/tty
            echo ""
            echo "🚀 Installing with your configuration..."
            echo ""
            curl -fsSL "$REPO_URL/install_cloudflare.sh" -o "$TMP_DIR/install_cloudflare.sh" && sh "$TMP_DIR/install_cloudflare.sh" "$INTERVAL" "$HOSTNAME" "$NEXTDNS_URL" "$CF_TOKEN" "$CF_ZONE" "$CF_REC"
            echo ""
            read -p "Press Enter to return to menu..." < /dev/tty
            ;;
        2)
            curl -fsSL "$REPO_URL/install_wg.sh" -o "$TMP_DIR/install_wg.sh" && sh "$TMP_DIR/install_wg.sh"
            echo ""
            read -p "Press Enter to return to menu..." < /dev/tty
            ;;
        3)
            curl -fsSL "$REPO_URL/uninstall_all.sh" -o "$TMP_DIR/uninstall_all.sh" && sh "$TMP_DIR/uninstall_all.sh"
            echo ""
            read -p "Press Enter to return to menu..." < /dev/tty
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
