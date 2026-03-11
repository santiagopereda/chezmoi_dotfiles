#!/bin/sh
# Show CPU temperature — supports lm_sensors (x86) and vcgencmd (Pi)
if command -v sensors >/dev/null 2>&1; then
  sensors 2>/dev/null | awk '/Package id 0|Tctl/{match($0,/[0-9]+\.[0-9]+°C/); printf " %s", substr($0,RSTART,RLENGTH); exit}'
elif command -v vcgencmd >/dev/null 2>&1; then
  temp=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2)
  [ -n "$temp" ] && printf " %s" "$temp"
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
  raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
  [ -n "$raw" ] && printf " %d°C" "$((raw / 1000))"
fi
