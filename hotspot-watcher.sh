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

    # Try different DHCP methods in order of preference
    
    # Method 1: Try dnsmasq first (if available)
    if command -v dnsmasq >/dev/null 2>&1; then
      pkill -f "dnsmasq --interface=$IF" 2>/dev/null
      dnsmasq --interface="$IF" --bind-interfaces --dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},12h --no-hosts --keep-in-foreground >/dev/null 2>&1 &
      sleep 1
      log "Started dnsmasq on $IF (dhcp ${DHCP_RANGE_START}-${DHCP_RANGE_END})"
    
    # Method 2: Try BusyBox udhcpd
    elif command -v busybox >/dev/null 2>&1 && busybox --help | grep -q udhcpd; then
      # Create simple udhcpd config
      UDHCPD_CONF="/data/local/tmp/udhcpd-$IF.conf"
      cat > "$UDHCPD_CONF" << EOF
start $DHCP_RANGE_START
end $DHCP_RANGE_END
interface $IF
option router $TARGET_IP
option dns 8.8.8.8 8.8.4.4
lease_file /data/local/tmp/udhcpd-$IF.leases
EOF
      pkill -f "udhcpd.*$IF" 2>/dev/null
      busybox udhcpd -f "$UDHCPD_CONF" >/dev/null 2>&1 &
      log "Started BusyBox udhcpd on $IF (dhcp ${DHCP_RANGE_START}-${DHCP_RANGE_END})"
    
    # Method 3: Fall back to system DHCP
    else
      log "No external DHCP daemon found, relying on system DHCP for $IF"
      # Force routing table to ensure our IP is used as gateway
      ip route add 192.168.1.0/24 dev "$IF" 2>/dev/null || true
    fi
  done

  # Sleep to avoid CPU burn; adjust if necessary
  sleep 5
done