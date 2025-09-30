# Hotspot Gateway Magisk Module

This Magisk module forces your phone's hotspot interface to use `192.168.1.1` and automatically configures DHCP so connecting clients receive `192.168.1.1` as their default gateway.

## Requirements

- Root with Magisk
- `service.d` support (Magisk typically provides it)
- **No additional software required** - the module automatically detects and uses available DHCP methods

## How It Works

The module automatically tries different DHCP methods in order of preference:

1. **dnsmasq** - Full-featured DNS/DHCP server (if installed via Termux: `pkg install dnsmasq`)
2. **BusyBox udhcpd** - Lightweight DHCP server (commonly pre-installed on Android)
3. **System DHCP** - Falls back to Android's built-in DHCP with forced gateway routing

## Installation

1. Download or create the flashable ZIP file
2. Flash the ZIP in Magisk Manager (Install → Install from storage)
3. Reboot your device
4. Enable Hotspot - the module automatically detects and configures hotspot interfaces

## Customization

Edit `hotspot-watcher.sh` before creating the flashable ZIP to customize:

- `TARGET_IP=192.168.1.1` — Gateway IP address
- `DHCP_RANGE_START=192.168.1.10` — First IP in DHCP pool
- `DHCP_RANGE_END=192.168.1.100` — Last IP in DHCP pool
- `NETMASK=255.255.255.0` — Network subnet mask

## Creating Flashable ZIP

Use the included script to create a flashable ZIP:

```bash
chmod +x create-flashable-zip.sh
./create-flashable-zip.sh
```

This generates `hotspot-gateway-v1.0.zip` ready for installation.

## Uninstall

**Via Magisk Manager:**
1. Open Magisk Manager
2. Go to Modules tab
3. Find "Hotspot Gateway" module
4. Tap the trash/remove button
5. Reboot

**Manual removal:**
```bash
rm /data/adb/service.d/hotspot-gateway.sh
rm /data/local/tmp/hotspot-gateway.*
reboot
```

## DHCP Method Details

### Method 1: dnsmasq (Preferred)
- **Install**: `pkg install dnsmasq` in Termux
- **Features**: Full DNS/DHCP server with advanced options
- **Best for**: Users who want maximum control and features

### Method 2: BusyBox udhcpd (Automatic fallback)
- **Availability**: Pre-installed on most Android devices
- **Features**: Lightweight DHCP server, basic functionality
- **Best for**: Most users (works out of the box)

### Method 3: System DHCP (Last resort)
- **Availability**: Always available
- **Features**: Uses Android's built-in DHCP with forced routing
- **Best for**: Devices where other methods aren't available

## Troubleshooting

**Check module status:**
```bash
# View logs
cat /data/local/tmp/hotspot-gateway.log

# Check if service is running
ps | grep hotspot-gateway
```

**Manual testing:**
```bash
# Test DHCP methods available
command -v dnsmasq && echo "dnsmasq available"
busybox --help | grep -q udhcpd && echo "udhcpd available"
```

## Notes & Compatibility

- **ROM Compatibility**: Some vendor ROMs may reset hotspot settings aggressively. The module continuously monitors and reconfigures interfaces as needed.
- **No Root Apps**: Works independently - doesn't interfere with hotspot management apps.
- **Multiple Interfaces**: Automatically detects and configures all hotspot-related interfaces (`wlan`, `ap0`, `softap`, `uap`, `rndis`).
- **Battery Impact**: Minimal - checks interfaces every 5 seconds only when hotspot might be active.