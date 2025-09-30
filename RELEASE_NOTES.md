# Release Notes for Hotspot Gateway v1.0

## 🚀 Initial Release

**Hotspot Gateway** is a Magisk module that forces your Android device's hotspot interface to use `192.168.1.1` as the gateway IP and automatically configures DHCP for connected clients.

### ✨ Features

- **Automatic Gateway Configuration**: Forces hotspot interface to use `192.168.1.1`
- **Multi-Method DHCP Support**: Automatically detects and uses the best available DHCP method
- **No Dependencies Required**: Works out-of-the-box on most Android devices
- **Intelligent Fallback System**: 
  1. dnsmasq (if installed via Termux)
  2. BusyBox udhcpd (commonly pre-installed)
  3. System DHCP (always available)

### 📋 Requirements

- Android device with root access
- Magisk v20.4+ installed
- No additional software required

### 🔧 Installation

1. Download `hotspot-gateway-v1.0.zip` from the release assets
2. Open Magisk Manager
3. Go to Modules tab → Install from storage
4. Select the downloaded ZIP file
5. Reboot your device
6. Enable hotspot - the module will automatically configure it

### 🎛️ Configuration

Default settings:
- Gateway IP: `192.168.1.1`
- DHCP Range: `192.168.1.10` - `192.168.1.100`
- Subnet: `255.255.255.0`

To customize, edit `hotspot-watcher.sh` before creating the ZIP using the included `create-flashable-zip.sh` script.

### 🔍 Troubleshooting

Check module logs:
```bash
cat /data/local/tmp/hotspot-gateway.log
```

### 🗑️ Uninstall

Remove the module from Magisk Manager or manually delete `/data/adb/service.d/hotspot-gateway.sh` and reboot.

---

**Full Changelog**: Initial release

**Tested on**: Various Android ROMs with Magisk v20.4+