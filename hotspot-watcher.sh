#!/system/bin/sh
# hotspot-watcher.sh
# Runs at boot (service.d). Monitors for hotspot interface(s) and forces IP/gateway to 192.168.1.1

TARGET_IP=192.168.1.1
NETMASK=255.255.255.0
DHCP_RANGE_START=192.168.1.10
DHCP_RANGE_END=192.168.1.100
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

# Background worker: monitor interfaces for AP/hotspot
while true; do
  # list candidate interfaces that often correspond to AP/hotspot
  for IF in $(ip -o link show | awk -F': ' '/wlan|ap0|softap|uap|rndis/ {print $2}'); do
    # skip loopback
    [ "$IF" = "lo" ] && continue
    # check operstate
    STATE=$(cat /sys/class/net/$IF/operstate 2>/dev/null || echo down)
    if [ "$STATE" != "up" ]; then
      continue
    fi

    # If interface already has our target IP, skip
    if ip addr show dev "$IF" 2>/dev/null | grep -q "$TARGET_IP"; then
      continue
    fi

    # Try to configure interface IP (requires root)
    ifconfig "$IF" "$TARGET_IP" netmask "$NETMASK" 2>/dev/null && \
      log "Set $IF -> $TARGET_IP/$NETMASK"

    # Kill any existing dnsmasq started by this script
    pkill -f "dnsmasq --interface=$IF" 2>/dev/null

    # Start dnsmasq on that interface (if dnsmasq binary present)
    if command -v dnsmasq >/dev/null 2>&1; then
      dnsmasq --interface="$IF" --bind-interfaces --dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},12h --no-hosts --keep-in-foreground >/dev/null 2>&1 &
      sleep 1
      log "Started dnsmasq on $IF (dhcp ${DHCP_RANGE_START}-${DHCP_RANGE_END})"
    else
      log "dnsmasq not found: clients may not receive DHCP from this module. Install dnsmasq (e.g. via Termux)."
    fi
  done

  # Sleep to avoid CPU burn; adjust if necessary
  sleep 5
done