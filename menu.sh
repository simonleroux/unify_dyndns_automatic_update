#!/bin/sh
# Unifi_scripts Main Menu

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
            echo "Enter interval (minutes): "
            read -r INTERVAL < /dev/tty
            echo "Enter Hostname: "
            read -r HOSTNAME < /dev/tty
            echo "Enter NextDNS URL: "
            read -r NEXTDNS_URL < /dev/tty
            echo "Enter CF Token: "
            read -r CF_TOKEN < /dev/tty
            echo "Enter CF Zone ID: "
            read -r CF_ZONE < /dev/tty
            echo "Enter CF Record ID: "
            read -r CF_REC < /dev/tty
            ./install_cloudflare.sh "$INTERVAL" "$HOSTNAME" "$NEXTDNS_URL" "$CF_TOKEN" "$CF_ZONE" "$CF_REC"
            ;;
        2)
            ./install_wg.sh
            ;;
        3)
            ./uninstall_all.sh
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
