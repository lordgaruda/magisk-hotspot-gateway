#!/system/bin/sh
# hotspot-watcher.sh (Using BusyBox udhcpd)

TARGET_IP=192.168.1.1
NETMASK=255.255.255.0
DHCP_RANGE_START=192.168.1.10
DHCP_RANGE_END=192.168.1.100
LOG=/data/local/tmp/hotspot-gateway.log
PIDFILE=/data/local/tmp/hotspot-gateway.pid
UDHCPD_CONF=/data/local/tmp/udhcpd.conf

log() {
  echo "$(date '+%F %T') $*" >> "$LOG"
}

create_udhcpd_config() {
  local interface=$1
  cat > "$UDHCPD_CONF" << EOF
start $DHCP_RANGE_START
end $DHCP_RANGE_END
interface $interface
max_leases 50
auto_time 7200
decline_time 3600
conflict_time 3600
offer_time 60
min_lease 60
lease_file /data/local/tmp/udhcpd.leases
pidfile /data/local/tmp/udhcpd.pid
option subnet $NETMASK
option router $TARGET_IP
option dns 8.8.8.8 8.8.4.4
option lease 43200
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

    # Kill existing udhcpd processes
    pkill -f "udhcpd.*$UDHCPD_CONF" 2>/dev/null

    # Try different udhcpd locations
    for UDHCPD_BIN in /system/bin/udhcpd /system/xbin/udhcpd busybox; do
      if command -v "$UDHCPD_BIN" >/dev/null 2>&1; then
        create_udhcpd_config "$IF"
        if [ "$UDHCPD_BIN" = "busybox" ]; then
          busybox udhcpd -f "$UDHCPD_CONF" &
        else
          "$UDHCPD_BIN" -f "$UDHCPD_CONF" &
        fi
        log "Started udhcpd ($UDHCPD_BIN) on $IF"
        break
      fi
    done
  done

  sleep 5
done