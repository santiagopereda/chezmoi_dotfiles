#!/bin/sh
# Show battery level on laptops, plug icon on desktops/Pi
bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -1)

if [ -z "$bat" ]; then
  # No battery — show plug icon (desktop/Pi)
  printf "󰚥"
  exit 0
fi

capacity=$(cat "$bat/capacity" 2>/dev/null)
[ -z "$capacity" ] && exit 0

ac=$(find /sys/class/power_supply -maxdepth 1 -name 'AC*' -o -name 'ADP*' 2>/dev/null | head -1)
if [ -n "$ac" ] && [ "$(cat "$ac/online" 2>/dev/null)" = "1" ]; then
  printf " %s%%" "$capacity"
else
  printf "󰂀 %s%%" "$capacity"
fi
