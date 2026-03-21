#!/bin/sh
# Show latency to active SSH target, or nothing if no session

case "$(uname -s)" in
  Darwin)
    # macOS: use lsof to find established SSH connections
    remote=$(lsof -i :22 -sTCP:ESTABLISHED -nP 2>/dev/null \
      | awk '/->/{split($9,a,"->"); split(a[2],b,":"); print b[1]; exit}')
    timeout="-W 1000"
    ;;
  *)
    # Linux: use ss (socket stats)
    remote=$(ss -tnH state established '( dport = 22 )' 2>/dev/null \
      | awk '{split($4,a,":"); print a[1]}' | head -1)
    timeout="-W 1"
    ;;
esac

[ -z "$remote" ] && exit 0

ping -c 1 $timeout "$remote" 2>/dev/null \
  | awk -F'time=' '/time=/{printf "󰢹 %.0f ms", $2}'
