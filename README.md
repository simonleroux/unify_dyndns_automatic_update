# STETNET Automatic IP Update for UniFi Devices

Automatically update NextDNS and Cloudflare DNS records on UniFi gateways. This is specifically designed for UniFi devices behind CGNAT or on dynamic IP connections.

---

## ✅ Features

- 🛡️ Automatically checks if public IP matches DNS resolution before updating
- 🔁 Runs once at boot and every N minutes (default: 5)
- 🧩 Integrates via `systemd` service and timer
- 🧼 Fully contained in `/data/STETNET/automatic_update`
- 🔄 Supports NextDNS and Cloudflare API (A Records)
- 🧠 Designed and tested for UniFi OS Version >4.x (UCG Ultra, etc.)

---

## 🚀 Installation

To install, pipe the script to `sh` and provide your configuration as arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/simonleroux/unify_dyndns_automatic_update/main/install.sh | sh -s -- [INTERVAL] [HOSTNAME] [NEXTDNS_URL] [CF_TOKEN] [CF_ZONE_ID] [CF_RECORD_ID]
```

### Example (Every 5 minutes):
```bash
curl -fsSL https://raw.githubusercontent.com/simonleroux/unify_dyndns_automatic_update/main/install.sh | sh -s -- 5 "my.home.com" "https://link-to-nextdns.io/update" "your_cf_token" "zone_id" "record_id"
```

---

## 🧼 Uninstallation

To completely remove the service, timer, and configuration:

```bash
curl -fsSL https://raw.githubusercontent.com/simonleroux/unify_dyndns_automatic_update/main/uninstall.sh | sh
```

---

## 🩺 Check Health

A helper script is included to monitor status:

```bash
sh /data/STETNET/automatic_update/status.sh
```

This shows:
- Service & timer status
- Time remaining until next update
- Last execution logs and API responses

---

## 🛠️ Systemd Service Controls

Manage the update service manually:

```bash
# Run the update script immediately
systemctl start automatic_update.service

# View current status
systemctl status automatic_update.service

# Stop/Start the periodic timer
systemctl stop automatic_update.timer
systemctl start automatic_update.timer

# View timer schedule
systemctl list-timers --all | grep automatic_update
```

---

## 📝 License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Contributing

Contributions are welcome! Feel free to fork the repository, submit pull requests, or suggest improvements.