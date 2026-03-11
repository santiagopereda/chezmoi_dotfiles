#!/bin/sh
# Show latency to active SSH target, or nothing if no session
# Detect SSH connections via ss (socket stats) — reliable, no grep-on-ps fragility
remote=$(ss -tnH state established '( dport = 22 )' 2>/dev/null \
  | awk '{split($4,a,":"); print a[1]}' | head -1)

[ -z "$remote" ] && exit 0

ping -c 1 -W 1 "$remote" 2>/dev/null \
  | awk -F'time=' '/time=/{printf "󰢹 %.0f ms", $2}'
