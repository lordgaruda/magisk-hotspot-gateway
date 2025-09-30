#!/system/bin/sh
# hotspot-watcher.sh (Using dhcpd/ISC DHCP)

TARGET_IP=192.168.1.1
NETMASK=255.255.255.0
DHCP_RANGE_START=192.168.1.10
DHCP_RANGE_END=192.168.1.100
LOG=/data/local/tmp/hotspot-gateway.log
PIDFILE=/data/local/tmp/hotspot-gateway.pid
DHCP_CONF=/data/local/tmp/dhcpd.conf

log() {
  echo "$(date '+%F %T') $*" >> "$LOG"
}

create_dhcp_config() {
  local interface=$1
  cat > "$DHCP_CONF" << EOF
default-lease-time 43200;
max-lease-time 86400;
authoritative;

subnet 192.168.1.0 netmask 255.255.255.0 {
  range $DHCP_RANGE_START $DHCP_RANGE_END;
  option routers $TARGET_IP;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  option broadcast-address 192.168.1.255;
}
EOF
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

    # Kill existing DHCP processes
    pkill -f "dhcpd.*$IF" 2>/dev/null

    # Start dhcpd if available
    if command -v dhcpd >/dev/null 2>&1; then
      create_dhcp_config "$IF"
      dhcpd -cf "$DHCP_CONF" -pf "/data/local/tmp/dhcpd-$IF.pid" "$IF" 2>/dev/null &
      log "Started dhcpd on $IF"
    else
      log "dhcpd not found, using system DHCP"
    fi
  done

  sleep 5
done