#!/system/bin/sh
# hotspot-watcher.sh (Manual IP assignment via ARP monitoring)

TARGET_IP=192.168.1.1
NETMASK=255.255.255.0
LOG=/data/local/tmp/hotspot-gateway.log
PIDFILE=/data/local/tmp/hotspot-gateway.pid
NEXT_IP=10  # Start assigning from 192.168.1.10

log() {
  echo "$(date '+%F %T') $*" >> "$LOG"
}

assign_ip_to_client() {
  local interface=$1
  local mac=$2
  local ip="192.168.1.$NEXT_IP"
  
  # Use static ARP entry
  arp -s "$ip" "$mac" 2>/dev/null
  log "Assigned $ip to MAC $mac on $interface"
  
  NEXT_IP=$((NEXT_IP + 1))
  if [ $NEXT_IP -gt 100 ]; then
    NEXT_IP=10  # Wrap around
  fi
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

while true; do
  for IF in $(ip -o link show | awk -F': ' '/wlan|ap0|softap|uap|rndis/ {print $2}'); do
    [ "$IF" = "lo" ] && continue
    STATE=$(cat /sys/class/net/$IF/operstate 2>/dev/null || echo down)
    if [ "$STATE" != "up" ]; then
      continue
    fi

    if ip addr show dev "$IF" 2>/dev/null | grep -q "$TARGET_IP"; then
      continue
    fi

    ifconfig "$IF" "$TARGET_IP" netmask "$NETMASK" 2>/dev/null && \
      log "Set $IF -> $TARGET_IP/$NETMASK"

    # Monitor for new MAC addresses (clients connecting)
    ip neigh show dev "$IF" | while read ip lladdr mac nud state; do
      if [ "$lladdr" = "lladdr" ] && [ "$nud" = "REACHABLE" ]; then
        # New client detected, assign IP if not already assigned
        if ! arp -a | grep -q "$mac"; then
          assign_ip_to_client "$IF" "$mac"
        fi
      fi
    done
  done

  sleep 10
done