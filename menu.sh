#!/bin/sh
# Unifi_scripts Main Menu

show_menu() {
    echo "====================================="
    echo "       STETNET Unifi Scripts         "
    echo "====================================="
    echo "1) Install Automatic Cloudflare/NextDNS Update"
    echo "2) Install WireGuard Failover"
    echo "3) Uninstall All"
    echo "4) Exit"
    echo "====================================="
}

while true; do
    show_menu
    read -p "Select an option [1-4]: " choice
    case $choice in
        1)
            # Interactive installation for Cloudflare/NextDNS
            echo "Enter interval (minutes): "
            read INTERVAL
            echo "Enter Hostname: "
            read HOSTNAME
            echo "Enter NextDNS URL: "
            read NEXTDNS_URL
            echo "Enter CF Token: "
            read CF_TOKEN
            echo "Enter CF Zone ID: "
            read CF_ZONE
            echo "Enter CF Record ID: "
            read CF_REC
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
