#!/usr/bin/env bash
set -u

# A6 camera discovery workflow for a local network.
# Run this from a Windows/Linux machine that can reach your LAN.
#
# Usage:
#   ./a6-camera-discovery.sh
#   ./a6-camera-discovery.sh 192.168.0.0/24
#   ./a6-camera-discovery.sh 192.168.0.22

TARGET="${1:-192.168.0.0/24}"
PREFIX="${TARGET%/*}"
PORTS=(80 81 554 8080 8554 8899)

if command -v nmap >/dev/null 2>&1; then
  NMAP=1
else
  NMAP=0
fi

if command -v python3 >/dev/null 2>&1; then
  PYTHON=1
else
  PYTHON=0
fi

if [[ "$TARGET" == *"/"* ]]; then
  # CIDR range
  if command -v python3 >/dev/null 2>&1; then
    mapfile -t HOSTS < <(python3 - "$TARGET" <<'PY'
import ipaddress, sys
net = ipaddress.ip_network(sys.argv[1], strict=False)
for ip in net:
    if ip == net.network_address or ip == net.broadcast_address:
        continue
    print(str(ip))
PY
)
  else
    echo "python3 is required for CIDR support." >&2
    exit 1
  fi
else
  HOSTS=("$TARGET")
fi

printf '\n=== A6 camera local discovery ===\n'
printf 'Target range: %s\n\n' "$TARGET"

for host in "${HOSTS[@]}"; do
  if ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
    echo "[LIVE] $host"

    for port in "${PORTS[@]}"; do
      if command -v nc >/dev/null 2>&1; then
        if nc -z -w 2 "$host" "$port" >/dev/null 2>&1; then
          echo "  Port $port OPEN"
        fi
      elif command -v python3 >/dev/null 2>&1; then
        if python3 - "$host" "$port" <<'PY'
import socket, sys
host = sys.argv[1]
port = int(sys.argv[2])
try:
    s = socket.create_connection((host, port), timeout=2)
    s.close()
    print("OPEN")
except Exception:
    pass
PY
        then
          echo "  Port $port OPEN"
        fi
      fi
    done

    for port in 80 81 8080 8899; do
      if curl -fsS "http://$host:$port/" >/tmp/a6_camera_http_probe.txt 2>/dev/null; then
        echo "  HTTP page reachable at http://$host:$port/"
        break
      fi
    done

    echo
  fi
done

printf '\n=== Suggested next checks ===\n'
printf '1. Log into the web UI on the live IP and look for RTSP settings.\n'
printf '2. Test common RTSP URLs: rtsp://admin:admin@IP:554/stream1\n'
printf '3. Reserve the IP in your router as a DHCP static lease.\n'
printf '4. Add a Home Assistant camera config using the verified RTSP URL.\n\n'

printf 'Example Home Assistant config:\n'
printf '  stream:\n\n'
printf '  camera:\n'
printf '    - platform: ffmpeg\n'
printf '      name: A6 Camera\n'
printf '      input: rtsp://admin:admin@192.168.0.22:554/stream1\n\n'

exit 0
