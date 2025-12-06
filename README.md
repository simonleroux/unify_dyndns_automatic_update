# SILER DynDNS auto-update for CGNAT UNIFY devices

Automatically update freeDNS on UniFi gateways. This is needed for CGNAT Unify devices.

---

## ✅ Features

- 🛡️ Automatically check and update freeDNS
- 🔁 Runs once at boot and every N minutes (default: 5)
- 🧩 Integrates via `systemd` service and timer
- 🧼 Fully contained in `/data/STETNET/freedns_update`
- 🔄 Supports uninstall and safe re-install
- 🧠 Designed and tested for UniFi OS Version >4.3.9 on UCG ULTRA

---

## 🚀 Installation

To install with a 5-minute interval (default):

```bash
curl -fsSL https://raw.githubusercontent.com/simonleroux/unify_dyndns_automatic_update/main/install.sh | sh -s -- 5 hostname directUrlUpdate
```

Replace `5` with your desired interval in minutes.
replace `hostname` with your hostname 
replace `directUrlUpdate` with the link to update freedns

---

## 🧼 Uninstallation

To completely remove the service, timer, and MSS rules:

```bash
curl -fsSL https://raw.githubusercontent.com/simonleroux/unify_dyndns_automatic_update/main/uninstall.sh | sh
```

---

## 🩺 Check Health

A helper script is included:

```bash
sh /data/STETNET/freedns_update/status.sh
```

This shows:
- Service & timer status
- Next timer run
- Last execution logs

---

## 🛠️ Systemd Service Controls

Manage the freeDNS update service manually:

```bash
# Start the freeDNS update script immediately
systemctl start freedns_update.service

# View current status
systemctl status freedns_update.service

# Stop the periodic timer
systemctl stop freedns_update.timer

# Restart both service and timer
systemctl restart freedns_update.service
systemctl restart freedns_update.timer
```

---

> 💡 The service will reapply the rules at the next scheduled interval or can be triggered manually using `systemctl freedns_update.service`.

---

## 📌 Notes

---

## 📝 License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Contributing

Contributions are welcome! Feel free to fork the repository, submit pull requests, or suggest improvements.
