#!/bin/sh
# Show CPU temperature — supports lm_sensors (x86), vcgencmd (Pi), sysfs fallback
temp=""

# Try lm_sensors (x86)
if [ -z "$temp" ] && command -v sensors >/dev/null 2>&1; then
  temp=$(sensors 2>/dev/null | awk '/Package id 0|Tctl/{match($0,/[0-9]+\.[0-9]+°C/); print substr($0,RSTART,RLENGTH); exit}')
fi

# Try vcgencmd (Pi with working firmware interface)
if [ -z "$temp" ] && command -v vcgencmd >/dev/null 2>&1; then
  temp=$(vcgencmd measure_temp 2>&1 | grep -o '[0-9]\+\.[0-9]\+.C')
fi

# Fallback to sysfs thermal zone
if [ -z "$temp" ] && [ -f /sys/class/thermal/thermal_zone0/temp ]; then
  raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
  [ -n "$raw" ] && temp="$((raw / 1000))°C"
fi

[ -n "$temp" ] && printf " %s" "$temp"
