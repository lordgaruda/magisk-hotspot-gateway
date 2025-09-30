#!/system/bin/sh
# Magisk module installer (simple): copies service script to service.d
MODDIR=${0%/*}

# Make sure service.d exists
mkdir -p /data/adb/service.d

# Copy watcher script into service.d
cp "$MODDIR/hotspot-watcher.sh" /data/adb/service.d/hotspot-gateway.sh
chmod 0755 /data/adb/service.d/hotspot-gateway.sh

# Create log directory
mkdir -p /data/local/tmp
chmod 0755 /data/local/tmp

# Inform
echo "[Hotspot Gateway] Installed service script to /data/adb/service.d/hotspot-gateway.sh"
echo "Reboot to activate. Make sure a dnsmasq binary is present on the device (e.g. installed via Termux)."

exit 0