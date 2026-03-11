#!/bin/sh
# Show weather — cached for 15 minutes to avoid hammering wttr.in
cache=/tmp/tmux_weather
now=$(date +%s)

if [ -f "$cache" ]; then
  age=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
  if [ "$((now - age))" -lt 900 ]; then
    cat "$cache"
    exit 0
  fi
fi

result=$(curl -s -m 2 'wttr.in?format=%c%t' 2>/dev/null)

# wttr.in returns error strings starting with "Unknown" or HTML on failure
case "$result" in
  Unknown*|""|*"<"*) exit 0 ;;
esac

printf '%s' "$result" > "$cache"
printf '%s' "$result"
