#!/system/bin/sh
# hotspot-watcher.sh (Using Android's built-in DHCP)
# Forces hotspot interface IP to 192.168.1.1 and relies on system DHCP

TARGET_IP=192.168.1.1
NETMASK=255.255.255.0
LOG=/data/local/tmp/hotspot-gateway.log
PIDFILE=/data/local/tmp/hotspot-gateway.pid

log() {
  echo "$(date '+%F %T') $*" >> "$LOG"
}

# Prevent multiple instances
if [ -f "$PIDFILE" ]; then
  if kill -0 "$(cat $PIDFILE)" >/dev/null 2>&1; then
    exit 0
  else
    rm -f "$PIDFILE"
  fi
fi

echo $$ > "$PIDFILE"

# Monitor interfaces for AP/hotspot
while true; do
  for IF in $(ip -o link show | awk -F': ' '/wlan|ap0|softap|uap|rndis/ {print $2}'); do
    [ "$IF" = "lo" ] && continue
    STATE=$(cat /sys/class/net/$IF/operstate 2>/dev/null || echo down)
    if [ "$STATE" != "up" ]; then
      continue
    fi

    # If interface already has our target IP, skip
    if ip addr show dev "$IF" 2>/dev/null | grep -q "$TARGET_IP"; then
      continue
    fi

    # Configure interface IP
    ifconfig "$IF" "$TARGET_IP" netmask "$NETMASK" 2>/dev/null && \
      log "Set $IF -> $TARGET_IP/$NETMASK (using system DHCP)"

    # Optional: Force routing table update
    ip route add 192.168.1.0/24 dev "$IF" 2>/dev/null
    
    # Let Android's built-in DHCP server handle client assignments
    # It should automatically use the interface IP as gateway
  done

  sleep 5
done