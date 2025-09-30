# Hotspot Gateway Magisk Module

This Magisk module forces your phone's hotspot interface to use `192.168.1.1` and runs `dnsmasq` on that interface so connecting clients receive `192.168.1.1` as their default gateway.

## Requirements

- Root with Magisk
- `service.d` support (Magisk typically provides it)
- `dnsmasq` binary available on the device (this module does not include dnsmasq). You can install dnsmasq via Termux (`pkg install dnsmasq`) and make sure the `dnsmasq` binary is available in PATH (or place it in `/system/bin` if you know what you're doing).

## Installation

1. Create a ZIP containing the module folder (`magisk-hotspot-gateway/`) preserving the file layout shown above.
2. Flash the ZIP in Magisk Manager (Install from storage).
3. Reboot.
4. Enable Hotspot. The module watches for hotspot interfaces and sets the IP to `192.168.1.1` when it detects them.

## Customize

If you want a different gateway or DHCP range, edit `hotspot-watcher.sh` before zipping:
- `TARGET_IP` — gateway IP
- `DHCP_RANGE_START`/`DHCP_RANGE_END` — DHCP pool

## Uninstall

- Remove the module from Magisk Manager or delete `/data/adb/service.d/hotspot-gateway.sh` and reboot.

## Notes & Caveats

- Some vendor ROMs may aggressively reset hotspot settings; this module attempts to reconfigure the interface when it sees it up. If the ROM actively overwrites the IP after we set it, you may need a more integrated patch (ROM-level edits or a Magisk module that modifies the tethering binaries).
- `dnsmasq` must be available for DHCP to work. Without it, connected clients may get no DHCP address or may receive addresses from the system DHCP (likely with the old gateway).
- This script is intentionally simple. If you prefer, I can make it more robust (detect interface by checking `iw`/hostapd state, add a clean restart on hotspot toggle, or bundle dnsmasq). Let me know.