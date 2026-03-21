#!/bin/sh
# Show battery level on laptops, plug icon on desktops/Pi

case "$(uname -s)" in
  Darwin)
    batt_info=$(pmset -g batt 2>/dev/null)
    capacity=$(echo "$batt_info" | grep -o '[0-9]\{1,3\}%' | head -1 | tr -d '%')
    if [ -z "$capacity" ]; then
      printf "󰚥"
      exit 0
    fi
    if echo "$batt_info" | grep -q 'AC Power'; then
      printf " %s%%" "$capacity"
    else
      printf "󰂀 %s%%" "$capacity"
    fi
    ;;
  *)
    bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -1)
    if [ -z "$bat" ]; then
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
    ;;
esac
