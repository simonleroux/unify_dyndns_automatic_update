#!/bin/sh
# STETNET Overall MSS Clamping Installer with customizable interval

MSS_DIR="/data/STETNET/freedns_update"
SERVICE_NAME="freedns_update.service"
TIMER_NAME="freedns_update.timer"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TIMER_PATH="/etc/systemd/system/$TIMER_NAME"

INTERVAL_MIN="${1:-5}"
HOSTNAME="$2"
DIRECTURLUPDATE="$3"

printf "Checking if we should change $HOSTNAME IP resolution\n"